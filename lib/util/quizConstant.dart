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

//  CAPA 1: SHARED PREFERENCES (Solo iconos/categorías para UI rápida)
class QuizSharedPrefs {
  static const String _keyCategories = 'quiz_categories';
  static const String _keyIcons = 'quiz_icon_names';

  /// Guarda solo las categorías e iconos para mostrar rápido en perfil
  static Future<void> saveQuickData({
    required List<String> categories,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Guardamos categorías como JSON string
      await prefs.setString(_keyCategories, jsonEncode(categories));

      // Guardamos nombres de iconos (para poder reconstruir los IconData)
      final iconNames = categories
          .map((cat) => QuizConstants.categoryIcons[cat]?.codePoint.toString() ?? '')
          .toList();
      await prefs.setString(_keyIcons, jsonEncode(iconNames));
    } catch (e) {
      print('Error saving to SharedPreferences: $e');
    }
  }

  /// Obtiene las categorías guardadas
  static Future<List<String>> getCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = prefs.getString(_keyCategories);

      if (categoriesJson == null) return [];

      return List<String>.from(jsonDecode(categoriesJson));
    } catch (e) {
      print('Error reading from SharedPreferences: $e');
      return [];
    }
  }

  /// Obtiene los iconos para mostrar en Home
  static Future<List<IconData>> getIcons() async {
    try {
      final categories = await getCategories();

      if (categories.isEmpty) return [Icons.psychology];

      return categories
          .map((cat) => QuizConstants.categoryIcons[cat] ?? Icons.psychology)
          .toList();
    } catch (e) {
      print('Error getting icons: $e');
      return [Icons.psychology];
    }
  }

  /// Limpia los datos (cuando hace logout o reset)
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyCategories);
      await prefs.remove(_keyIcons);
    } catch (e) {
      print('Error clearing SharedPreferences: $e');
    }
  }
}

//  CAPA 2: LRU CACHE
class QuizLRUCache {
  static UserQuizResult? _cachedResult;

  /// Guarda en caché LRU (solo el último resultado)
  static Future<void> save(UserQuizResult result) async {
    _cachedResult = result;
  }

  /// Obtiene el resultado en caché
  static Future<UserQuizResult?> get() async {
    return _cachedResult;
  }

  /// Limpia el caché
  static Future<void> clear() async {
    _cachedResult = null;
  }
}

//  CAPA 3: ARCHIVO LOCAL (Persistencia offline completa)
class QuizFileStorage {
  static const String _fileName = 'quiz_latest_result.json';

  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// Guarda el resultado completo en archivo local
  static Future<void> save(UserQuizResult result) async {
    try {
      final file = await _getFile();
      final jsonString = jsonEncode(result.toMap());
      await file.writeAsString(jsonString);
    } catch (e) {
      print('Error saving to file: $e');
      rethrow;
    }
  }

  /// Lee el último resultado del archivo
  static Future<UserQuizResult?> read() async {
    try {
      final file = await _getFile();

      if (!await file.exists()) return null;

      final jsonString = await file.readAsString();
      final map = jsonDecode(jsonString) as Map<String, dynamic>;

      return UserQuizResult.fromMap(map);
    } catch (e) {
      print('Error reading from file: $e');
      return null;
    }
  }

  /// Limpia el archivo
  static Future<void> clear() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error clearing file: $e');
    }
  }
}

//  CAPA 4: FIREBASE
class QuizFirebaseStorage {

  static final FirebaseFirestore _db = FirebaseService.firestore;

  /// Guarda en Firebase (crea o actualiza en una sola operación)
  static Future<void> save({
    required UserQuizResult result,
    FirebaseFirestore? firestore,
  }) async {
    final db = firestore ?? _db;

    try {
      final userDocRef =
      db.collection('quiz_answers').doc(result.userId);

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
      await db.collection('quiz_answers').doc(userId).get();

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

  static Future<void> clearResult(String userId) async {
    final doc = _db.collection('quiz_answers').doc(userId);

    final snapshot = await doc.get();
    if (snapshot.exists) {
      await doc.delete();
    }
  }

}


// ============ GESTOR MAESTRO (Coordina todas las capas) ============
class QuizStorageManager {
  /// Guarda el resultado en TODAS las capas de forma coordinada
  static Future<void> saveResult(UserQuizResult result) async {
    // CAPA 1: SharedPreferences (datos rápidos para UI)
    await QuizSharedPrefs.saveQuickData(
      categories: result.resultCategories,
    );

    // CAPA 2: LRU Cache (en memoria)
    await QuizLRUCache.save(result);

    // CAPA 3: Archivo local (persistencia offline)
    try {
      await QuizFileStorage.save(result);
    } catch (e) {
      print('Warning: Failed to save to local file: $e');
    }

    // CAPA 4: Firebase (si hay internet)
    try {
      await QuizFirebaseStorage.save(result: result);
    } catch (e) {
      print('Warning: Failed to save to Firebase (offline?): $e');
      // No lanzamos error, el usuario puede estar offline
    }
  }

  /// Obtiene el resultado más reciente (busca en orden: Cache → Archivo → Firebase)
  static Future<UserQuizResult?> getLatestResult(String userId) async {
    // 1. Intenta desde caché LRU (más rápido)
    var result = await QuizLRUCache.get();
    if (result != null) {
      print('Loaded from LRU cache');
      return result;
    }

    // 2. Intenta desde archivo local
    try {
      result = await QuizFileStorage.read();
      if (result != null) {
        print('Loaded from local file');
        // Lo ponemos en caché para la próxima
        await QuizLRUCache.save(result);
        return result;
      }
    } catch (e) {
      print('Error reading local file: $e');
    }

    // 3. Intenta desde Firebase (si hay internet)
    try {
      result = await QuizFirebaseStorage.read(userId: userId);
      if (result != null) {
        print('Loaded from Firebase');
        // Lo guardamos en las capas locales
        await QuizLRUCache.save(result);
        await QuizFileStorage.save(result);
        return result;
      }
    } catch (e) {
      print('Error reading from Firebase: $e');
    }

    return null;
  }


  static Future<bool> _hasInternet() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// Limpia TODAS las capas (útil para logout o reset)
  static Future<void> clearAll(String userId) async {
    // SIEMPRE borrar local (offline-safe)
    debugPrint('ClearAll: borrando local');

    await Future.wait([
      QuizSharedPrefs.clear(),
      QuizLRUCache.clear(),
      QuizFileStorage.clear(),
    ]);

    debugPrint('ClearAll: local OK');

    //  Verificamos internet ANTES
    final hasInternet = await _hasInternet();

    if (!hasInternet) {
      debugPrint('ClearAll: sin internet → no tocar Firebase');
      return; //
    }

    // Firebase SOLO si hay red
    try {
      debugPrint('ClearAll: borrando Firebase');
      await QuizFirebaseStorage.clearResult(userId);
      debugPrint('ClearAll: Firebase OK');
    } catch (e) {
      debugPrint('ClearAll: Firebase error $e');
    }
  }



  /// Obtiene iconos para mostrar en Home (solo SharedPreferences, super rápido)
  static Future<List<IconData>> getHomeIcons() async {
    return await QuizSharedPrefs.getIcons();
  }
  static Future<List<String>> getCategories() async {
    return await QuizSharedPrefs.getCategories();
  }
}