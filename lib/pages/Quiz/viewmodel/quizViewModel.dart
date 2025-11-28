import 'dart:isolate';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../util/firebase_service.dart';
import '../model/optionModel.dart';
import '../model/questionModel.dart';


class QuizViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  //  Data
  List<Question> _selectedQuestions = [];
  int _currentIndex = 0;
  bool _loading = false;
  bool _completed = false;

  //  Scoring
  final Map<String, int> _scores = {
    'cultural_explorer': 0,
    'social_planner': 0,
    'creative': 0,
    'chill': 0,
  };

  final Map<String, Option> _userAnswers = {};

  //  Getters (UI)
  List<Question> get questions => _selectedQuestions;

  bool get isLoading => _loading;
  bool get isCompleted => _completed;

  int get currentIndex => _currentIndex;

  Question get currentQuestion => _selectedQuestions[_currentIndex];

  bool get isLast => _currentIndex == _selectedQuestions.length - 1;
  bool get isFirst => _currentIndex == 0;

  Option? get currentAnswer => _userAnswers[currentQuestion.id];

  Map<String, int> get scores => Map.unmodifiable(_scores);

  QuizViewModel() {
    // caché de Firebase para que funcione offline
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }



  Future<void> loadQuiz() async {
    _loading = true;
    notifyListeners();

    try {
      final doc = await _firestore
          .collection('quiz_questions')
          .doc('lOhEPYC8ci9lBEo08G47')
          .get();

      final data = doc.data();
      if (data == null) return;

      final List questionsRaw = data['questions'];

      final allQuestions = questionsRaw.map((q) => Question.fromMap(q)).toList();

      allQuestions.shuffle(Random());
      _selectedQuestions = allQuestions.take(5).toList();
      _currentIndex = 0;
      _completed = false;

      // Limpiamos respuestas y scores anteriores
      _userAnswers.clear();
      _scores.updateAll((key, value) => 0);

      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      notifyListeners();
    }
  }

  void nextQuestion() {
    if (_currentIndex < _selectedQuestions.length - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  void answerQuestion(Option selectedOption) {
    final questionId = currentQuestion.id;

    // Si el usuario ya había respondido esta pregunta, restamos el puntaje anterior
    if (_userAnswers.containsKey(questionId)) {
      final oldOption = _userAnswers[questionId]!;
      _scores[oldOption.category] = (_scores[oldOption.category] ?? 0) - oldOption.points;
    }

    // Guardamos la nueva respuesta
    _userAnswers[questionId] = selectedOption;

    // Sumamos el puntaje de la nueva respuesta
    _scores[selectedOption.category] = (_scores[selectedOption.category] ?? 0) + selectedOption.points;

    // Si es la última pregunta, marcamos como completado
    if (isLast) {
      _completed = true;
    }

    notifyListeners();
  }









  Future<Map<String, dynamic>> calculateResult() async {
    final receivePort = ReceivePort();

    await Isolate.spawn(
      _calculateInIsolate,
      {
        'sendPort': receivePort.sendPort,
        'scores': _scores,
      },
    );

    return await receivePort.first;
  }
  static void _calculateInIsolate(Map<String, dynamic> data) {
    final SendPort sendPort = data['sendPort'];
    final Map<String, int> scores = Map<String, int>.from(data['scores']);

    final maxScore = scores.values.reduce(max);

    final winners = scores.entries.where((e) => e.value == maxScore).map((e) => e.key).toList();

    if (winners.length == 1) {
      sendPort.send({
        'type': 'single',
        'categories': winners,
      });
      return;
    }

    if (winners.length == 2) {
      sendPort.send({
        'type': 'mixed',
        'categories': winners,
      });
      return;
    }

    const priority = ['cultural_explorer', 'social_planner', 'creative', 'chill'];

    for (final p in priority) {
      if (winners.contains(p)) {
        sendPort.send({
          'type': 'tie_priority',
          'categories': [p],
        });
        return;
      }
    }
  }

  Future<void> saveResult({
    required String userId,
    required Map<String, dynamic> result,
  }) async {
    // Referencia al documento del usuario
    final userDocRef = _firestore.collection('quiz_answers').doc(userId);

    // Nuevo resultado a agregar
    final newResult = {
      'quizBankId': 'personality_v1',
      'timestamp': FieldValue.serverTimestamp(), // Mejor que DateTime.now()
      'selectedQuestionIds': _selectedQuestions.map((q) => q.id).toList(),
      'scores': _scores,
      'resultCategory': result['categories'],
      'resultType': result['type'],
    };

    // Verificamos si el documento ya existe
    final docSnapshot = await userDocRef.get();

    if (docSnapshot.exists) {
      // ✅ SI EXISTE: Agregamos el nuevo resultado al array 'results'
      await userDocRef.update({
        'results': FieldValue.arrayUnion([newResult]),
        'lastUpdated': FieldValue.serverTimestamp(),
        'totalQuizzes': FieldValue.increment(1), // Contador de cuántos ha hecho
      });
    } else {
      // ✅ NO EXISTE: Creamos el documento con el primer resultado
      await userDocRef.set({
        'userId': userId,
        'results': [newResult], // Array con el primer resultado
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'totalQuizzes': 1,
      });
    }
  }
}