
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quiver/collection.dart';

import '../pages/FreeTime/model/event.dart';
import '../pages/events/model/event.dart' as EventsModel;


class EventStorageService {
  late LruMap<String, List<Map<String, dynamic>>> _cache;
  final int _maxCacheSize = 5;
  static const String _storageFileName = 'events_freeTime.json';

  EventStorageService() {
    _cache = LruMap(maximumSize: _maxCacheSize);
    debugPrint(' LRU Cache initialized (max: $_maxCacheSize)');
  }

  // ========== SAVE ==========

  /// Guarda los 3 primeros eventos en cache y en disco
  Future<void> saveUserEvents(String userId, List<EventsModel.Event> events) async {
    print("guardando cache");
    final top3 = events.take(3).map((e) {
      final json = e.toJson();
      json['id'] = e.id; // Agrega el ID manualmente
      return json;
    }).toList();
    _cache[userId] = top3;
    await _saveToLocalStorage();
    debugPrint('Guardados ${top3.length} eventos para $userId');
  }

  // ========== LOAD ==========

  /// Intenta cargar desde cache → disco
  Future<List<Map<String, dynamic>>> loadUserEvents(String userId) async {
    final cached = _cache[userId];
    if (cached != null && cached.isNotEmpty) {
      debugPrint('Cache HIT para $userId');
      return cached;
    }

    await _loadFromLocalStorage();
    final stored = _cache[userId];
    if (stored != null && stored.isNotEmpty) {
      debugPrint(' LocalStorage HIT para $userId');
      return stored;
    }

    debugPrint('No hay eventos en cache ni disco para $userId');
    return [];
  }

  // ========== PERSISTENCIA ==========

  Future<void> _saveToLocalStorage() async {
    try {
      final file = await _getStorageFile();
      final Map<String, dynamic> serializableCache = {};
      _cache.forEach((key, value) {
        serializableCache[key] = value;
      });
      final jsonData = jsonEncode(serializableCache);

      await file.writeAsString(jsonData);
      debugPrint(' Cache persistida en disco');
    } catch (e) {
      debugPrint(' Error guardando en disco: $e');
    }
  }

  Future<void> _loadFromLocalStorage() async {
    try {
      final file = await _getStorageFile();
      if (!await file.exists()) return;

      final contents = await file.readAsString();
      final Map<String, dynamic> raw = jsonDecode(contents);
      _cache.clear();
      raw.forEach((userId, eventList) {
        final parsed = List<Map<String, dynamic>>.from(eventList);
        _cache[userId] = parsed;
      });

      debugPrint(' Cache cargada desde disco (${_cache.length} usuarios)');
    } catch (e) {
      debugPrint(' Error leyendo desde disco: $e');
    }
  }

  Future<File> _getStorageFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_storageFileName');
  }

  // ========== UTILIDADES ==========

  void clearCache() => _cache.clear();

  Future<void> clearLocalStorage() async {
    try {
      final file = await _getStorageFile();
      if (await file.exists()) await file.delete();
      debugPrint(' Local storage eliminado');
    } catch (e) {
      debugPrint(' Error limpiando disco: $e');
    }
  }
}
