import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

import 'firebase_service.dart';

import 'package:connectivity_plus/connectivity_plus.dart';





//  ICONOS Y CONSTANTES
class QuizConstants {
  static const Map<String, IconData> categoryIcons = {
    'cultural_explorer': Icons.museum,
    'social_planner': Icons.people,
    'creative': Icons.palette,
    'chill': Icons.spa,
  };

  static const Map<String, Color> categoryColors = {
    'cultural_explorer': Color(0xFF9C27B0),
    'social_planner': Color(0xFF2196F3),
    'creative': Color(0xFFFF9800),
    'chill': Color(0xFF4CAF50),
  };

  static const Map<String, String> categoryDescriptions = {
    'cultural_explorer':
    '🎭 You love discovering new cultural experiences and exploring art, history, and diverse perspectives.',
    'social_planner':
    '🎉 You enjoy organizing events and connecting with others. You thrive in social settings.',
    'creative':
    '🎨 You seek to express yourself and experiment with innovative ideas. Creativity drives you.',
    'chill':
    '😌 You prefer calm environments and relaxing activities. Balance and peace are important to you.',
  };

  static String getMixedDescription(List<String> categories) {
    final cat1 = categories[0];
    final cat2 = categories[1];
    return 'You have a balanced personality combining ${_formatCategory(cat1)} and ${_formatCategory(cat2)} traits. This mix makes you versatile and adaptable!';
  }

  static String _formatCategory(String category) {
    return category.replaceAll('_', ' ').toLowerCase();
  }

  static String getCategoryName(String category) {
    return category.replaceAll('_', ' ').toUpperCase();
  }

}

//  MODELO DE RESULTADO
class UserQuizResult {
  final String userId;
  final String quizId;
  final DateTime timestamp;
  final List<String> selectedQuestionIds;
  final Map<String, int> scores;
  final List<String> resultCategories;
  final String resultType;

  UserQuizResult({
    required this.userId,
    required this.quizId,
    required this.timestamp,
    required this.selectedQuestionIds,
    required this.scores,
    required this.resultCategories,
    required this.resultType,
  });

  Map<String, dynamic> toMap() {
    return {
      "userId": userId,
      "quizBankId": quizId,
      "timestamp": timestamp.toIso8601String(),
      "selectedQuestionIds": selectedQuestionIds,
      "scores": scores,
      "resultCategory": resultCategories,
      "resultType": resultType,
    };
  }

  factory UserQuizResult.fromMap(Map<String, dynamic> map) {
    return UserQuizResult(
      userId: map['userId'] ?? '',
      quizId: map['quizBankId'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      selectedQuestionIds: List<String>.from(map['selectedQuestionIds'] ?? []),
      scores: Map<String, int>.from(map['scores'] ?? {}),
      resultCategories: List<String>.from(map['resultCategory'] ?? []),
      resultType: map['resultType'] ?? '',
    );
  }
}

// ============ CAPA 1: SHARED PREFERENCES (POR USUARIO) ============
class QuizSharedPrefs {
  // Keys DINÁMICAS por usuario
  static String _categoriesKey(String userId) =>
      'quiz_categories_$userId';

  static String _iconsKey(String userId) =>
      'quiz_icon_names_$userId';

  /// Guarda solo las categorías e iconos para mostrar rápido en perfil
  static Future<void> saveQuickData({
    required String userId,
    required List<String> categories,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Guardamos categorías como JSON string
      await prefs.setString(
        _categoriesKey(userId),
        jsonEncode(categories),
      );

      // Guardamos nombres de iconos (para poder reconstruir los IconData)
      final iconNames = categories
          .map(
            (cat) =>
        QuizConstants.categoryIcons[cat]?.codePoint.toString() ?? '',
      )
          .toList();

      await prefs.setString(
        _iconsKey(userId),
        jsonEncode(iconNames),
      );
    } catch (e) {
      debugPrint('Error saving to SharedPreferences: $e');
    }
  }

  /// Obtiene las categorías guardadas del usuario actual
  static Future<List<String>> getCategories(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = prefs.getString(_categoriesKey(userId));

      if (categoriesJson == null) return [];

      return List<String>.from(jsonDecode(categoriesJson));
    } catch (e) {
      debugPrint('Error reading categories from SharedPreferences: $e');
      return [];
    }
  }

  /// Obtiene los iconos para mostrar en Home (por usuario)
  static Future<List<IconData>> getIcons(String userId) async {
    try {
      final categories = await getCategories(userId);

      if (categories.isEmpty) return [Icons.psychology];

      return categories
          .map(
            (cat) =>
        QuizConstants.categoryIcons[cat] ?? Icons.psychology,
      )
          .toList();
    } catch (e) {
      debugPrint('Error getting icons from SharedPreferences: $e');
      return [Icons.psychology];
    }
  }

  /// Limpia SOLO los datos del usuario actual
  static Future<void> clear(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_categoriesKey(userId));
      await prefs.remove(_iconsKey(userId));
    } catch (e) {
      debugPrint('Error clearing SharedPreferences: $e');
    }
  }
}


// ============ CAPA 2: LRU CACHE (POR USUARIO) ============
class QuizLRUCache {
  // Cache en memoria por usuario (LRU = solo último resultado)
  static final Map<String, UserQuizResult> _cachedResults = {};

  /// Guarda en caché LRU (solo el último resultado del usuario)
  static Future<void> save({
    required String userId,
    required UserQuizResult result,
  }) async {
    _cachedResults[userId] = result;
  }

  /// Obtiene el resultado en caché del usuario
  static Future<UserQuizResult?> get(String userId) async {
    return _cachedResults[userId];
  }

  /// Limpia el caché del usuario
  static Future<void> clear(String userId) async {
    _cachedResults.remove(userId);
  }

  /// Limpia todo el caché (debug / memory pressure)
  static Future<void> clearAll() async {
    _cachedResults.clear();
  }
}


// ============ CAPA 3: ARCHIVO LOCAL (POR USUARIO) ============
class QuizFileStorage {
  /// Nombre de archivo dinámico por usuario
  static String _fileName(String userId) =>
      'quiz_latest_result_$userId.json';

  static Future<File> _getFile(String userId) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/${_fileName(userId)}');
  }

  /// Guarda el resultado completo en archivo local
  static Future<void> save({
    required String userId,
    required UserQuizResult result,
  }) async {
    try {
      final file = await _getFile(userId);
      final jsonString = jsonEncode(result.toMap());
      await file.writeAsString(jsonString);
    } catch (e) {
      debugPrint('Error saving quiz result to file: $e');
      rethrow;
    }
  }

  /// Lee el último resultado del usuario desde archivo local
  static Future<UserQuizResult?> read(String userId) async {
    try {
      final file = await _getFile(userId);

      if (!await file.exists()) return null;

      final jsonString = await file.readAsString();
      final map = jsonDecode(jsonString) as Map<String, dynamic>;

      return UserQuizResult.fromMap(map);
    } catch (e) {
      debugPrint('Error reading quiz result from file: $e');
      return null;
    }
  }

  /// Limpia el archivo local del usuario
  static Future<void> clear(String userId) async {
    try {
      final file = await _getFile(userId);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error clearing quiz file: $e');
    }
  }
}


// ============ CAPA 4: FIREBASE ============
class QuizFirebaseStorage {
  static final FirebaseFirestore _db = FirebaseService.firestore;

  /// Guarda en Firebase (create/update atómico por usuario)
  static Future<void> save({
    required UserQuizResult result,
    FirebaseFirestore? firestore,
  }) async {
    final db = firestore ?? _db;

    try {
      final userDocRef =
      db.collection('user_quiz_results').doc(result.userId);

      await userDocRef.set(
        {
          'userId': result.userId,
          'latestResult': result.toMap(),
          'lastUpdated': FieldValue.serverTimestamp(),
          'totalQuizzes': FieldValue.increment(1),
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e, s) {
      debugPrint('Error saving quiz result: $e\n$s');
      rethrow;
    }
  }

  /// Lee el último resultado desde Firebase
  static Future<UserQuizResult?> read({
    required String userId,
    FirebaseFirestore? firestore,
  }) async {
    final db = firestore ?? _db;

    try {
      final doc =
      await db.collection('user_quiz_results').doc(userId).get();

      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null || data['latestResult'] == null) return null;

      return UserQuizResult.fromMap(
        Map<String, dynamic>.from(data['latestResult']),
      );
    } catch (e, s) {
      debugPrint('Error reading quiz result: $e\n$s');
      return null;
    }
  }

  /// Borra SOLO el resultado del usuario (logout/reset)
  static Future<void> clearResult(String userId) async {
    final doc = _db.collection('user_quiz_results').doc(userId);

    final snapshot = await doc.get();
    if (snapshot.exists) {
      await doc.delete();
    }
  }
}



// ============ GESTOR MAESTRO ============
class QuizStorageManager {
  /// Guarda el resultado en TODAS las capas
  static Future<void> saveResult(UserQuizResult result) async {
    final userId = result.userId;

    // CAPA 1: SharedPreferences (UI rápida)
    await QuizSharedPrefs.saveQuickData(
      userId: userId,
      categories: result.resultCategories,
    );

    // CAPA 2: LRU Cache (RAM)
    await QuizLRUCache.save(
      userId: userId,
      result: result,
    );

    // CAPA 3: Archivo local (offline)
    try {
      await QuizFileStorage.save(
        userId: userId,
        result: result,
      );
    } catch (e) {
      debugPrint('Warning: Failed to save file: $e');
    }

    // CAPA 4: Firebase (si hay internet)
    try {
      if (await _hasInternet()) {
        await QuizFirebaseStorage.save(result: result);
      }
    } catch (e) {
      debugPrint('Firebase offline or error: $e');
    }
  }

  /// Obtiene el último resultado (LRU → Archivo → Firebase)
  static Future<UserQuizResult?> getLatestResult(String userId) async {
    // 1️⃣ LRU Cache
    var result = await QuizLRUCache.get(userId);
    if (result != null) {
      debugPrint('Loaded from LRU');
      return result;
    }

    // 2️⃣ Archivo local
    result = await QuizFileStorage.read(userId);
    if (result != null) {
      debugPrint('Loaded from file');
      await QuizLRUCache.save(userId: userId, result: result);
      return result;
    }

    // 3️⃣ Firebase
    if (await _hasInternet()) {
      result = await QuizFirebaseStorage.read(userId: userId);
      if (result != null) {
        debugPrint('Loaded from Firebase');
        await QuizLRUCache.save(userId: userId, result: result);
        await QuizFileStorage.save(userId: userId, result: result);
        return result;
      }
    }

    return null;
  }

  /// Limpia TODAS las capas (logout / retake)
  static Future<void> clearAll(String userId) async {
    debugPrint('ClearAll: limpiando capas locales');

    await Future.wait([
      QuizSharedPrefs.clear(userId),
      QuizLRUCache.clear(userId),
      QuizFileStorage.clear(userId),
    ]);

    if (!await _hasInternet()) return;

    try {
      await QuizFirebaseStorage.clearResult(userId);
      debugPrint('Firebase limpiado');
    } catch (e) {
      debugPrint('Firebase clear error: $e');
    }
  }

  /// Utilidades UI rápidas (POR USUARIO)
  static Future<List<IconData>> getHomeIcons(String userId) async {
    if (userId.isEmpty) return [Icons.question_mark];
    return QuizSharedPrefs.getIcons(userId);
  }

  static Future<List<String>> getCategories(String userId) async {
    if (userId.isEmpty) return [];
    return QuizSharedPrefs.getCategories(userId);
  }

  /// Internet check
  static Future<bool> _hasInternet() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  static Future<void> syncPendingQuizToFirebase(String userId) async {
    // 1. Leer quiz desde archivo local
    final localResult = await QuizFileStorage.read(userId);

    if (localResult == null) {
      debugPrint('No pending quiz to sync');
      return;
    }

    if (localResult.userId != userId) {
      debugPrint('Pending quiz belongs to another user');
      return;
    }

    try {
      debugPrint('Syncing pending quiz to Firebase...');
      await QuizFirebaseStorage.save(result: localResult);

      debugPrint('Quiz synced successfully ✅');
      // ⚠️ NO borrar archivo si quieres historial
      // await QuizFileStorage.clear();
    } catch (e) {
      debugPrint('Failed to sync quiz: $e');
    }
  }

}
