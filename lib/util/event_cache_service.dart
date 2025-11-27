import 'dart:math';
import 'package:app_flutter/pages/events/model/event.dart';
import 'package:app_flutter/pages/events/model/event_filter.dart';
import 'package:app_flutter/util/local_DB_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:quiver/collection.dart';

class EventsCacheService {
  static final EventsCacheService _instance = EventsCacheService._internal();
  factory EventsCacheService() => _instance;
  EventsCacheService._internal();

  // LRU Cache for quick access (Firebase handles its own internal cache too)
  final LruMap<String, List<Event>> _cache = LruMap<String, List<Event>>(maximumSize: 10);
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
    // Ensure DB is initialized
    await LocalUserService().database;
    debugPrint('EventsCacheService initialized');
  }

  // ============== CACHE KEY GENERATION ==============

  String _getCacheKey(EventFilters filters) {
    final parts = <String>[
      if (filters.searchQuery?.isNotEmpty ?? false) 'q:${filters.searchQuery}',
      if (filters.category != null) 'cat:${filters.category}',
      if (filters.city != null) 'city:${filters.city}',
      if (filters.minRating != null) 'rating:${filters.minRating}',
      if (filters.eventTypes != null) 'types:${filters.eventTypes!.join(',')}',
    ];
    return parts.join('_');
  }

  // ============== MAIN GET EVENTS METHOD ==============

  Future<List<Event>> getEvents(EventFilters filters) async {
    final cacheKey = _getCacheKey(filters);
    
    // 1. Check LRU cache first (fastest)
    if (_cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey];
      if (cached != null && cached.isNotEmpty) {
        debugPrint('LRU Cache HIT: $cacheKey');
        return cached;
      }

      debugPrint('LRU Cache EMPTY, continuing fetch...');
    }

    
    // 2. Check SQLite (persistent offline)
    final sqliteCached = await LocalUserService().getCachedEvents(cacheKey);
    if (sqliteCached != null && sqliteCached.isNotEmpty) {
      debugPrint('SQLite Cache HIT: $cacheKey (${sqliteCached.length} events)');
      _cache[cacheKey] = sqliteCached;
      return sqliteCached;
    }

    // 3. Check General Events Fallback (when specific cache is missing)
    final fallbackEvents = await LocalUserService().getAllEvents();
    if (fallbackEvents.isNotEmpty) {
      debugPrint('Fallback Events HIT: (${fallbackEvents.length} events)');
      // We don't cache these in LRU under the specific key to avoid pollution, 
      // or we could. For now, just returning them.
      return fallbackEvents;
    }

    
    // 4. Fetch from Firestore (Firebase handles its own internal cache)
    debugPrint('Fetching from Firestore: $cacheKey');
    final events = await _fetchFromFirestore(filters);

    _cache[cacheKey] = events;
    await LocalUserService().cacheEvents(cacheKey, events);
    
    return events;
  }

  // ============== FIRESTORE FETCHING ==============

  Future<List<Event>> _fetchFromFirestore(EventFilters filters) async {
    try {
      Query query = _firestore.collection('events');

      if (filters.category != null) {
        query = query.where('category', isEqualTo: filters.category);
      }

      if (filters.city != null) {
        query = query.where('location.city', isEqualTo: filters.city);
      }
      if (filters.minRating != null) {
        try {
          query = query.where('stats.rating', isGreaterThanOrEqualTo: filters.minRating);
        } catch (_) {
          debugPrint('Firestore cannot query stats.rating; will filter client-side');
        }
      }

      // Guard whereIn: Firestore allows max 10 items in whereIn and it fails on empty lists
      if (filters.eventTypes != null && filters.eventTypes!.isNotEmpty) {
        final types = filters.eventTypes!;
        if (types.length <= 10) {
          query = query.where('eventType', whereIn: types);
        } else {
          debugPrint('Too many eventTypes for whereIn; will filter client-side');
        }
      }

      final snapshot = await query.get();
      List<Event> events = snapshot.docs
          .map((doc) => Event.fromJson(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      if (filters.searchQuery?.isNotEmpty ?? false) {
        final searchLower = filters.searchQuery!.toLowerCase();
        events = events.where((event) {
          final title = event.title;
          final desc = event.description ;
          final name = event.name ;
          return title.toLowerCase().contains(searchLower) ||
                desc.toLowerCase().contains(searchLower) ||
                name.toLowerCase().contains(searchLower);
        }).toList();
      }

      if (filters.minRating != null) {
        events = events.where((e) => (e.stats.rating) >= filters.minRating!).toList();
      }

      if (filters.eventTypes != null && filters.eventTypes!.isNotEmpty) {
        final allowed = filters.eventTypes!;
        events = events.where((e) => allowed.contains(e.eventType)).toList();
      }

      debugPrint('Fetched ${events.length} events from Firestore');
      await saveEvents(events, filters);
      return events;
    } catch (e, st) {
      debugPrint('Error fetching from Firestore: $e\n$st');
      rethrow;
    }
  }

  Future<void> saveEvents(List<Event> events, EventFilters filters) async {
    // final key = _getCacheKey(filters); // Not used for general fallback

    final random = Random();
    final shuffled = List<Event>.from(events)..shuffle(random);
    final selected = shuffled.take(5).toList();

    // Save to general events table
    final cacheKey = _getCacheKey(filters);
    _cache[cacheKey] = selected;
    await LocalUserService().cacheEvents(cacheKey, selected);
    await LocalUserService().insertEvents(selected);
    debugPrint('Saved 5 events to general fallback table');
  }

  // ============== CACHE MANAGEMENT ==============

  /// Clear LRU cache only (keep SQLite)
  void clearMemoryCache() {
    _cache.clear();
    debugPrint('LRU cache cleared');
  }

  /// Clear SQLite only (keep LRU)
  Future<void> clearPersistentCache() async {
    await LocalUserService().clearCacheTable();
  }

  /// Clear all caches
  Future<void> clearAllCache() async {
    clearMemoryCache();
    await clearPersistentCache();
    debugPrint('All caches cleared');
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    // This would need to be added to LocalUserService if we want exact counts, 
    // but for now we can skip or add a count method there.
    // For simplicity, returning basic info.
    return {
        'lruCacheSize': _cache.length,
        'lruMaxSize': _cache.maximumSize,
    };
  }

  /// Preload specific filter from SQLite to LRU
  Future<void> preloadCache(EventFilters filters) async {
    final cacheKey = _getCacheKey(filters);
    
    if (_cache.containsKey(cacheKey)) {
      debugPrint('Already in LRU cache: $cacheKey');
      return;
    }

    final sqliteCached = await LocalUserService().getCachedEvents(cacheKey);
    if (sqliteCached != null) {
      _cache[cacheKey] = sqliteCached;
      debugPrint('Preloaded $cacheKey to LRU cache');
    }
  }
}