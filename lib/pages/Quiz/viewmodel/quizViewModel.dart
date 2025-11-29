import 'dart:isolate';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../../util/analytics_service.dart';
import '../../../util/firebase_service.dart';
import '../../../util/local_DB_service.dart';
import '../../../util/quizConstant.dart'; // ← NUEVO import
import '../model/optionModel.dart';
import '../model/questionModel.dart';

class QuizViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  // ============ DATA ============
  List<Question> _selectedQuestions = [];
  int _currentIndex = 0;
  bool _loading = true;
  bool _completed = false;

  // NUEVO: Guardamos las respuestas del usuario para cada pregunta
  // Key = questionId, Value = la opción que seleccionó
  final Map<String, Option> _userAnswers = {};

  // ============ SCORING ============
  final Map<String, int> _scores = {
    'cultural_explorer': 0,
    'social_planner': 0,
    'creative': 0,
    'chill': 0,
  };

  // ============ GETTERS (para la UI) ============
  List<Question> get questions => _selectedQuestions;
  bool get isLoading => _loading;
  bool get isCompleted => _completed;
  int get currentIndex => _currentIndex;
  Question get currentQuestion => _selectedQuestions[_currentIndex];
  bool get isLast => _currentIndex == _selectedQuestions.length - 1;
  bool get isFirst => _currentIndex == 0;

  // NUEVO: Permite saber si el usuario ya respondió la pregunta actual
  Option? get currentAnswer => _userAnswers[currentQuestion.id];

  // NUEVO: Getter público para acceder a los scores desde la UI
  Map<String, int> get scores => Map.unmodifiable(_scores);

  // ============ CONFIGURACIÓN DE CACHÉ ============
  QuizViewModel() {
    // Activamos caché de Firebase para que funcione offline
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // ============ CARGAR PREGUNTAS ============
  Future<void> loadQuiz() async {
    _loading = true;
    notifyListeners();

    try {
      final localDb = LocalUserService();
      List<Map<String, dynamic>> questionsRaw = [];

      // PASO 1: Intentar desde SQLite primero
      final hasCachedQuestions = await localDb.hasQuizQuestions();

      if (hasCachedQuestions) {
        print('Cargando preguntas desde SQLite cache');
        questionsRaw = await localDb.getQuizQuestions();
      } else {
        print('No hay preguntas en caché, intentando Firebase');


        final connectivity = await Connectivity().checkConnectivity();
        final hasInternet = connectivity != ConnectivityResult.none;

        if (!hasInternet) {
          print('Sin internet, no se intenta Firebase');
          _loading = false;
          notifyListeners();
          return;
        }

        print('Internet disponible, intentando Firebase');

        // PASO 2: Intentar desde Firebase
        try {
          final doc = await _firestore
              .collection('quiz_questions')
              .doc('lOhEPYC8ci9lBEo08G47')
              .get();

          final data = doc.data();

          if (data != null && data['questions'] != null) {
            questionsRaw = List<Map<String, dynamic>>.from(data['questions']);


          }
        } catch (e) {
          print('Error descargando de Firebase: $e');


          if (questionsRaw.isEmpty) {
            // No hay preguntas ni en Firebase ni en SQLite
            _loading = false;
            notifyListeners();
            return;
          }
        }
      }

      // PASO 5: Convertir a objetos Question
      final allQuestions = questionsRaw
          .map((q) => Question.fromMap(q))
          .toList();

      // PASO 6: Seleccionar 5 aleatorias
      if (allQuestions.length >= 5) {
        allQuestions.shuffle(Random());
        _selectedQuestions = allQuestions.take(5).toList();
      } else {
        // Si hay menos de 5, usar todas
        _selectedQuestions = allQuestions;
      }

      _currentIndex = 0;
      _completed = false;

      // Limpiamos respuestas y scores anteriores
      _userAnswers.clear();
      _scores.updateAll((key, value) => 0);

      _loading = false;
      notifyListeners();

      print('✓ Quiz cargado con ${_selectedQuestions.length} preguntas');

      AnalyticsService().logMoodQuizOpened();

      // ---------- PASO 3 (AJUSTADO): Guardar en SQLite SOLO si estaba vacío ----------
      if (!hasCachedQuestions) {
        // En background, NO await
        localDb.saveQuizQuestions(questionsRaw).then(
              (_) => print('✓ Preguntas guardadas en SQLite'),
        ).catchError(
              (e) => print('Error guardando SQLite: $e'),
        );
      }

    } catch (e) {
      print('Error crítico cargando quiz: $e');
      _loading = false;
      notifyListeners();
    }
  }

  // ============ NAVEGACIÓN ENTRE PREGUNTAS ============
  // NUEVO: Método para avanzar a la siguiente pregunta
  void nextQuestion() {
    if (_currentIndex < _selectedQuestions.length - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  // NUEVO: Método para retroceder a la pregunta anterior
  void previousQuestion() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  // ============ RESPONDER PREGUNTA ============
  // NUEVO: Método que faltaba en tu código original
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

  // ============ CALCULAR RESULTADO (CON ISOLATE) ============
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

  // ============ GUARDAR RESULTADO ============
  Future<void> saveResult({
    required String userId,
    required Map<String, dynamic> result,
  }) async {
    // Creamos el objeto UserQuizResult completo
    final userResult = UserQuizResult(
      userId: userId,
      quizId: 'personality_v1',
      timestamp: DateTime.now(),
      selectedQuestionIds: _selectedQuestions.map((q) => q.id).toList(),
      scores: Map<String, int>.from(_scores),
      resultCategories: List<String>.from(result['categories']),
      resultType: result['type'].toString(),
    );

    // GUARDADO MAESTRO: Usa el QuizStorageManager que maneja:
    // 1. SharedPreferences (iconos/categorías para UI rápida)
    // 2. LRU Cache (en memoria)
    // 3. Archivo local (persistencia offline)
    // 4. Firebase (sincronización en la nube, solo si hay internet)
    await QuizStorageManager.saveResult(userResult);


  }

  // NUEVO: Obtener el último resultado del usuario
  Future<UserQuizResult?> getLatestResult(String userId) async {
    return await QuizStorageManager.getLatestResult(userId);
  }
}