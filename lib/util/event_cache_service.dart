import 'dart:convert';
import 'dart:math';
import 'package:app_flutter/pages/events/model/event.dart';
import 'package:app_flutter/pages/events/model/event_filter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:quiver/collection.dart';

class EventsCacheService {
  static final EventsCacheService _instance = EventsCacheService._internal();
  factory EventsCacheService() => _instance;
  EventsCacheService._internal();

  // LRU Cache for quick access (Firebase handles its own internal cache too)
  final LruMap<String, List<Event>> _cache = LruMap<String, List<Event>>(maximumSize: 10);
  
  // SQLite Database for persistent offline storage
  Database? _database;
  static const String _dbName = 'events_cache.db';
  static const String _tableName = 'cached_events';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
    await _initDatabase();
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
      debugPrint('LRU Cache HIT: $cacheKey');
      return _cache[cacheKey]!;
    }

  
    // 2. Check SQLite (persistent offline)
    final sqliteCached = await _getFromSQLite(cacheKey);
    if (sqliteCached != null && sqliteCached.isNotEmpty) {
      debugPrint('SQLite Cache HIT: $cacheKey (${sqliteCached.length} events)');
      _cache[cacheKey] = sqliteCached;
      return sqliteCached;
    }

    
    // 3. Fetch from Firestore (Firebase handles its own internal cache)
    debugPrint('Fetching from Firestore: $cacheKey');
    final events = await _fetchFromFirestore(filters);

    _cache[cacheKey] = events;
    await _storeInSQLite(cacheKey, events);
    
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
      return events;
    } catch (e, st) {
      debugPrint('Error fetching from Firestore: $e\n$st');
      rethrow;
    }
  }


  // ============== SQLITE DATABASE ==============

  Future<void> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName(
            cache_key TEXT PRIMARY KEY,
            events_json TEXT NOT NULL,
            cached_at INTEGER NOT NULL
          )
        ''');
        debugPrint('SQLite database created');
      },
    );
  }

  Future<List<Event>?> _getFromSQLite(String cacheKey) async {
  if (_database == null) await _initDatabase();
    try {
      final results = await _database!.query(
        _tableName,
        where: 'cache_key = ?',
        whereArgs: [cacheKey],
      );

      if (results.isEmpty) return null;

      final eventsJson = results.first['events_json'] as String;
      final List<dynamic> decoded = jsonDecode(eventsJson) as List<dynamic>;

      final List<Event> events = [];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final id = item['id'] as String?;
          final data = item['data'] as Map<String, dynamic>?;
          if (id != null && data != null) {
            events.add(Event.fromJson(id, data));
          }
        } else {
          debugPrint('Unexpected item type in cached events: ${item.runtimeType}');
        }
      }

      return events;
    } catch (e, st) {
      debugPrint('Error reading from SQLite: $e\n$st');
      return null;
    }
  }


  Future<void> _storeInSQLite(String cacheKey, List<Event> events) async {
    if (_database == null) await _initDatabase();

    try {
      final payload = events.map((e) => {
        'id': e.id,
        'data': e.toJson(),
      }).toList();

      final eventsJson = jsonEncode(payload);

      await _database!.insert(
        _tableName,
        {
          'cache_key': cacheKey,
          'events_json': eventsJson,
          'cached_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      debugPrint('Stored ${events.length} events in SQLite: $cacheKey');
      await _cleanOldEntries();
    } catch (e, st) {
      debugPrint('Error writing to SQLite: $e\n$st');
    }
  }

  Future<void> saveEvents(List<Event> events, EventFilters filters) async {
    final key = _getCacheKey(filters);

    final random = Random();
    final shuffled = List<Event>.from(events)..shuffle(random);
    final selected = shuffled.take(5).toList();

    _cache[key] = selected;
    await _storeInSQLite(key, selected);

  }



  Future<void> _cleanOldEntries() async {
    if (_database == null) return;
    
    try {
      final weekAgo = DateTime.now()
          .subtract(const Duration(days: 7))
          .millisecondsSinceEpoch;
      
      final deleted = await _database!.delete(
        _tableName,
        where: 'cached_at < ?',
        whereArgs: [weekAgo],
      );
      
      if (deleted > 0) {
        debugPrint('Cleaned $deleted old entries from SQLite');
      }
    } catch (e) {
      debugPrint('Error cleaning SQLite: $e');
    }
  }

  // ============== CACHE MANAGEMENT ==============

  /// Clear LRU cache only (keep SQLite)
  void clearMemoryCache() {
    _cache.clear();
    debugPrint('LRU cache cleared');
  }

  /// Clear SQLite only (keep LRU)
  Future<void> clearPersistentCache() async {
    if (_database == null) await _initDatabase();
    
    try {
      await _database!.delete(_tableName);
      debugPrint('SQLite cache cleared');
    } catch (e) {
      debugPrint('Error clearing SQLite: $e');
    }
  }

  /// Clear all caches
  Future<void> clearAllCache() async {
    clearMemoryCache();
    await clearPersistentCache();
    debugPrint('All caches cleared');
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    if (_database == null) await _initDatabase();
    
    try {
      final result = await _database!.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName'
      );
      final sqliteCount = Sqflite.firstIntValue(result) ?? 0;
      
      return {
        'lruCacheSize': _cache.length,
        'lruMaxSize': _cache.maximumSize,
        'sqliteEntriesCount': sqliteCount,
      };
    } catch (e) {
      return {
        'lruCacheSize': _cache.length,
        'lruMaxSize': _cache.maximumSize,
        'sqliteEntriesCount': 0,
      };
    }
  }

  /// Preload specific filter from SQLite to LRU
  Future<void> preloadCache(EventFilters filters) async {
    final cacheKey = _getCacheKey(filters);
    
    if (_cache.containsKey(cacheKey)) {
      debugPrint('Already in LRU cache: $cacheKey');
      return;
    }

    final sqliteCached = await _getFromSQLite(cacheKey);
    if (sqliteCached != null) {
      _cache[cacheKey] = sqliteCached;
      debugPrint('Preloaded $cacheKey to LRU cache');
    }
  }

  /// Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      debugPrint('Database closed');
    }
  }
}