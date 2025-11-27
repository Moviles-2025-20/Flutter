import 'package:app_flutter/pages/events/model/event.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

class LocalUserService {
  static final LocalUserService _instance = LocalUserService._internal();
  static Database? _db;

  factory LocalUserService() {
    return _instance;
  }

  LocalUserService._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_local.db');
    print("Creando base de datos en: $path");
    return await openDatabase(
      path,
      version: 4, // Increment version for schema change
      onConfigure: (db) async {
         await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        print("Ejecutando onCreate");
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        print("Ejecutando onUpgrade de $oldVersion a $newVersion");
        if (oldVersion < 3) {
           // Drop old table if exists to recreate with new schema
           await db.execute('DROP TABLE IF EXISTS saved_events');
        }
        // Ensure tables are created/updated
        await _createTables(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
  try {
    print("Creando tablas...");
    
    // Users table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        name TEXT,
        email TEXT,
        photo TEXT,
        major TEXT,
        gender TEXT,
        age INTEGER,
        indoorOutdoorScore INTEGER,
        favoriteCategories TEXT,
        freeTimeSlots TEXT,
        createdAt TEXT,
        synced INTEGER
      )
    ''');
    print("✓ Tabla 'users' creada");
    
    // Cached events table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_events(
        cache_key TEXT PRIMARY KEY,
        events_json TEXT NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');
    print("✓ Tabla 'cached_events' creada");

    // General events table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS events (
        id TEXT PRIMARY KEY,
        event_type TEXT,
        active INTEGER,
        category TEXT,
        created TEXT,
        description TEXT,
        name TEXT,
        title TEXT,
        type TEXT,
        weather_dependent INTEGER,
        location_city TEXT,
        location_type TEXT,
        location_address TEXT,
        location_coordinates TEXT,
        metadata TEXT,
        schedule TEXT,
        stats TEXT,
        saved_at INTEGER NOT NULL
      )
    ''');
    print("✓ Tabla 'events' creada");
    
    print("✓ Todas las tablas creadas correctamente");
  } catch (e) {
    print("✗ Error creando tablas: $e");
    rethrow;
  }
}

  // ================= USER METHODS =================

  Future<void> insertUser(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(
      'users',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> markUserAsSynced(String uid) async {
    final db = await database;
    await db.update(
      'users',
      {"synced": 1},
      where: 'id = ?',
      whereArgs: [uid],
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedUsers() async {
    final db = await database;
    return await db.query(
      'users',
      where: 'synced = ?',
      whereArgs: [0],
    );
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query('users');
  }

  Future<void> clearUsers() async {
    final db = await database;
    await db.delete('users');
  }

  Future<void> debugPrintUsers() async {
    final users = await getUsers();
    if(users.isEmpty){
      print("No hay usuarios");
    }
    for (final user in users) {
      print("Usuario local: ${user['id']} - Synced: ${user['synced']}");
    }
  }

  Future<void> deleteUser(String uid) async {
    final db = await database;
    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [uid],
    );
  }

  Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    final db = await database;
    await db.update(
      'users',
      updates,
      where: 'id = ?',
      whereArgs: [uid],
    );
  }

  Future<bool> userExists(String uid) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM users WHERE id = ?', [uid],
    );
    final count = Sqflite.firstIntValue(result);
    return count == 1;
  }

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [uid],
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }

  // ================= GENERAL EVENTS METHODS =================

  Future<void> insertEvents(List<Event> events) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('events'); // Clear existing fallback events
      for (final event in events) {
        await txn.insert(
          'events',
          {
            'id': event.id,
            'event_type': event.eventType,
            'active': event.active ? 1 : 0,
            'category': event.category,
            'created': event.created.toIso8601String(),
            'description': event.description,
            'name': event.name,
            'title': event.title,
            'type': event.type,
            'weather_dependent': event.weatherDependent ? 1 : 0,
            'location_city': event.location.city,
            'location_type': event.location.type,
            'location_address': event.location.address,
            'location_coordinates': jsonEncode(event.location.coordinates),
            'metadata': jsonEncode(event.metadata.toJson()),
            'schedule': jsonEncode(event.schedule.toJson()),
            'stats': jsonEncode(event.stats.toJson()),
            'saved_at': DateTime.now().millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<Event>> getAllEvents() async {
    final db = await database;
    final results = await db.query('events', orderBy: 'saved_at DESC');

    return results.map((row) {
      return Event(
        id: row['id'] as String,
        eventType: row['event_type'] as String,
        active: (row['active'] as int) == 1,
        category: row['category'] as String,
        created: DateTime.parse(row['created'] as String),
        description: row['description'] as String,
        location: EventLocation(
          city: row['location_city'] as String,
          type: row['location_type'] as String,
          address: row['location_address'] as String,
          coordinates: List<double>.from(jsonDecode(row['location_coordinates'] as String)),
        ),
        metadata: EventMetadata.fromJson(jsonDecode(row['metadata'] as String)),
        name: row['name'] as String,
        schedule: EventSchedule.fromJson(jsonDecode(row['schedule'] as String)),
        stats: EventStats.fromJson(jsonDecode(row['stats'] as String)),
        title: row['title'] as String,
        type: row['type'] as String,
        weatherDependent: (row['weather_dependent'] as int) == 1,
      );
    }).toList();
  }

  // ================= CACHED EVENTS METHODS =================

  Future<List<Event>?> getCachedEvents(String cacheKey) async {
    try {
      final db = await database;
      final results = await db.query(
        'cached_events',
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
          print('Unexpected item type in cached events: ${item.runtimeType}');
        }
      }

      return events;
    } catch (e) {
      print('Error reading from SQLite cache: $e');
      return null;
    }
  }

  Future<void> cacheEvents(String cacheKey, List<Event> events) async {
    try {
      final db = await database;
      final payload = events.map((e) => {
        'id': e.id,
        'data': e.toJson(),
      }).toList();

      final eventsJson = jsonEncode(payload);

      await db.insert(
        'cached_events',
        {
          'cache_key': cacheKey,
          'events_json': eventsJson,
          'cached_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // Trigger cleanup after saving
      await cleanOldCacheEntries();
    } catch (e) {
      print('Error writing to SQLite cache: $e');
    }
  }

  Future<void> cleanOldCacheEntries() async {
    try {
      final db = await database;
      final weekAgo = DateTime.now()
          .subtract(const Duration(days: 7))
          .millisecondsSinceEpoch;
      
      final deleted = await db.delete(
        'cached_events',
        where: 'cached_at < ?',
        whereArgs: [weekAgo],
      );
      
      if (deleted > 0) {
        print('Cleaned $deleted old entries from SQLite cache');
      }
    } catch (e) {
      print('Error cleaning SQLite cache: $e');
    }
  }

  Future<void> clearCacheTable() async {
    try {
      final db = await database;
      await db.delete('cached_events');
      print('SQLite cache cleared');
    } catch (e) {
      print('Error clearing SQLite cache: $e');
    }
  }
}
