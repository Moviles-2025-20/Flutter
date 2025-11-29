import 'dart:collection';
import 'package:app_flutter/pages/badges/model/user_badge.dart';


class CacheEntry {
  final List<UserBadge> data;
  final DateTime timestamp;
  CacheEntry(this.data) : timestamp = DateTime.now();

  // Manejo Politica Expiracion
  bool get isExpired => DateTime.now().difference(timestamp).inHours >= 1;
}


class UserBadgesLruCache {
  final int capacity;
  final LinkedHashMap<String, CacheEntry> _cache;

  UserBadgesLruCache({this.capacity = 10})
      : _cache = LinkedHashMap<String, CacheEntry>();

  /// Obtener datos del caché
  List<UserBadge>? get(String userId) {
    final entry = _cache[userId];
    if (entry == null) return null;

    //Verifica expiracion
    if (entry.isExpired) {
      _cache.remove(userId);
      return null;
    }
    _cache.remove(userId);
    _cache[userId] = entry;
    return entry.data;
  }

  /// Guardar datos en el caché
  void put(String userId, List<UserBadge> badges) {

    if (_cache.containsKey(userId)) {
      _cache.remove(userId);
    } 

    else if (_cache.length >= capacity) {
      _cache.remove(_cache.keys.first);
    }
    _cache[userId] = CacheEntry(badges);
  }

  /// Limpiar todo el caché (útil al cerrar sesión)
  void clear() {
    _cache.clear();
  }
}