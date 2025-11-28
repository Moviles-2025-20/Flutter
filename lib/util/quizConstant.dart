import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ============ ICONOS POR CATEGORÍA ============
class QuizConstants {
  // Mapeo de categorías a iconos
  static const Map<String, IconData> categoryIcons = {
    'cultural_explorer': Icons.museum,
    'social_planner': Icons.people,
    'creative': Icons.palette,
    'chill': Icons.spa,
  };

  // Mapeo de categorías a colores
  static const Map<String, Color> categoryColors = {
    'cultural_explorer': Color(0xFF9C27B0), // Morado
    'social_planner': Color(0xFF2196F3), // Azul
    'creative': Color(0xFFFF9800), // Naranja
    'chill': Color(0xFF4CAF50), // Verde
  };

  // Descripciones por categoría
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

  // Descripciones para resultados mixtos
  static String getMixedDescription(List<String> categories) {
    final cat1 = categories[0];
    final cat2 = categories[1];

    return 'You have a balanced personality combining ${_formatCategory(cat1)} and ${_formatCategory(cat2)} traits. This mix makes you versatile and adaptable!';
  }

  static String _formatCategory(String category) {
    return category.replaceAll('_', ' ').toLowerCase();
  }

  // Nombre de categorías formateado
  static String getCategoryName(String category) {
    return category.replaceAll('_', ' ').toUpperCase();
  }
}

// ============ CACHE LOCAL CON SHARED PREFERENCES ============
class QuizCache {
  static const String _keyLastResult = 'quiz_last_result';
  static const String _keyHasCompletedQuiz = 'quiz_has_completed';

  // Guardar último resultado en caché local
  static Future<void> saveLastResult(Map<String, dynamic> result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastResult, jsonEncode(result));
    await prefs.setBool(_keyHasCompletedQuiz, true);
  }

  // Obtener último resultado del caché
  static Future<Map<String, dynamic>?> getLastResult() async {
    final prefs = await SharedPreferences.getInstance();
    final resultString = prefs.getString(_keyLastResult);

    if (resultString == null) return null;

    try {
      return Map<String, dynamic>.from(jsonDecode(resultString));
    } catch (e) {
      return null;
    }
  }

  // Verificar si el usuario ha completado el quiz
  static Future<bool> hasCompletedQuiz() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasCompletedQuiz) ?? false;
  }

  // Limpiar caché (cuando hace retake)
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastResult);
    await prefs.setBool(_keyHasCompletedQuiz, false);
  }

  // Obtener iconos para mostrar en Home
  static Future<List<IconData>> getHomeIcons() async {
    final result = await getLastResult();
    if (result == null) return [Icons.psychology]; // Icono por defecto

    final categories = List<String>.from(result['categories'] ?? []);

    return categories
        .map((cat) => QuizConstants.categoryIcons[cat] ?? Icons.psychology)
        .toList();
  }
}