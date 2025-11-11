import 'dart:convert';
import 'dart:io';

import 'package:app_flutter/util/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:lru_cache/lru_cache.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:app_flutter/pages/events/model/comment.dart';
import 'package:sqflite/sqflite.dart'; 
import 'package:path/path.dart'; 

class CommentService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final LruCache<String, List<Comment>> _memoryCache =
      LruCache<String, List<Comment>>(50);

  final CacheManager _imageCache = DefaultCacheManager();

  static const String _commentsTable = 'event_comments'; 
  static const String _dbName = 'comments_storage.db'; 
  /// Load comments with priority:
  /// memory → local(JSON + SQLite) → Firebase (if online)
  Future<List<Comment>> loadComments(String eventId) async {
    // 1️⃣ Try memory cache
    try {
      final mem = await _memoryCache.get(eventId);
      if (mem != null && mem.isNotEmpty) {
        print('⚡ Loaded comments from LRU memory cache');
        return mem;
      }
    } catch (_) {}

    // 2️⃣ Load from local file (JSON)
    final localJsonComments = await _loadCommentsFromLocal(eventId);

    // 3️⃣ Load from SQLite
    final localSQLiteComments = await _loadCommentsFromSQLite(eventId);

    // 3333333333333333333333333333333333333333333333333 combinar ambos sin duplicar (por id)
    final Map<String, Comment> merged = {};
    for (final c in [...localJsonComments, ...localSQLiteComments]) {
      merged[c.id] = c;
    }
    final combinedLocal = merged.values.toList();

    if (combinedLocal.isNotEmpty) {
      print('📦 Loaded ${combinedLocal.length} comments from local storage (JSON + SQLite)');
      _memoryCache.put(eventId, combinedLocal);
      _refreshFirebaseInBackground(eventId);
      return combinedLocal;
    }

    // 4️⃣ Try Firebase if online
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity != ConnectivityResult.none) {
      final firebaseComments = await _loadCommentsFromFirebase(eventId);
      if (firebaseComments.isNotEmpty) {
        print('☁️ Loaded comments from Firebase');
        _memoryCache.put(eventId, firebaseComments);
        await _saveCommentsLocally(eventId, firebaseComments);
        await _saveCommentsToSQLite(eventId, firebaseComments); // 33333333333333333333333333333333333333333
        return firebaseComments;
      }
    }

    print('🚫 No comments found locally or remotely');
    return [];
  }

  /// Load from Firebase
  Future<List<Comment>> _loadCommentsFromFirebase(String eventId) async {
    try {
      final query = _firestore
          .collection("comments")
          .where("eventId", isEqualTo: eventId)
          .limit(100);

      final snapshot = await query.get();

      final comments = snapshot.docs.map((doc) {
        final data = doc.data();
        return Comment.fromJson(doc.id, data);
      }).toList();

      for (var c in comments) {
        if (c.imageUrl != null && c.imageUrl!.isNotEmpty) {
          try {
            await _imageCache.downloadFile(c.imageUrl!);
          } catch (_) {}
        }
      }

      return comments;
    } catch (e) {
      print("❌ Error loading Firebase comments: $e");
      return [];
    }
  }

  /// Load cached comments from local JSON
  Future<List<Comment>> _loadCommentsFromLocal(String eventId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/comments_cache.json');

      if (!await file.exists()) return [];

      final content = await file.readAsString();
      final List<dynamic> allComments = json.decode(content);

      final eventComments = allComments
          .where((c) => c["eventId"] == eventId)
          .map((c) => Comment.fromJson(
                c.containsKey('id') ? c['id'] as String : '',
                Map<String, dynamic>.from(c),
              ))
          .toList();

      return eventComments;
    } catch (e) {
      print("❌ Error reading local JSON comments: $e");
      return [];
    }
  }

  /// 3333333333333333333333333333333333333333333333333 Load cached comments from SQLite
  Future<List<Comment>> _loadCommentsFromSQLite(String eventId) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _dbName);

      final db = await openDatabase(
        path,
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
            CREATE TABLE $_commentsTable (
              id TEXT PRIMARY KEY,
              event_id TEXT,
              user_name TEXT,
              avatar TEXT,
              description TEXT,
              created TEXT,
              image_url TEXT
            )
          ''');
        },
      );

      final rows = await db.query(
        _commentsTable,
        where: 'event_id = ?',
        whereArgs: [eventId],
      );

      await db.close();

      if (rows.isEmpty) return [];

      return rows.map((row) {
        return Comment(
          id: row['id'] as String,
          userName: row['user_name'] as String,
          avatar: row['avatar'] as String,
          event_id: row['event_id'] as String,
          description: row['description'] as String,
          created: DateTime.parse(row['created'] as String),
          imageUrl: row['image_url'] as String?,
        );
      }).toList();
    } catch (e) {
      print('❌ Error reading comments from SQLite: $e');
      return [];
    }
  }

  /// Save comments to local JSON (offline created ones)
  Future<void> _saveCommentsLocally(
      String eventId, List<Comment> comments) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/comments_cache.json');

      List<dynamic> allComments = [];

      if (await file.exists()) {
        final content = await file.readAsString();
        allComments = json.decode(content);
      }

      allComments.removeWhere((c) => c["eventId"] == eventId);

      allComments.addAll(comments.map((c) => {
            "id": c.id,
            "userName": c.userName,
            "avatar": c.avatar,
            "eventId": c.event_id,
            "description": c.description,
            "created": c.created.toIso8601String(),
            "imageUrl": c.imageUrl ?? '',
          }));

      await file.writeAsString(json.encode(allComments));
      print("💾 Comments saved to local JSON cache");
    } catch (e) {
      print("❌ Error saving comments locally (JSON): $e");
    }
  }

  /// 3333333333333333333333333333333333333333333333333 Save comments to SQLite
  Future<void> _saveCommentsToSQLite(
      String eventId, List<Comment> comments) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _dbName);

      final db = await openDatabase(
        path,
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
            CREATE TABLE $_commentsTable (
              id TEXT PRIMARY KEY,
              event_id TEXT,
              user_name TEXT,
              avatar TEXT,
              description TEXT,
              created TEXT,
              image_url TEXT
            )
          ''');
        },
      );

      await db.delete(_commentsTable, where: 'event_id = ?', whereArgs: [eventId]);

      for (var c in comments) {
        await db.insert(
          _commentsTable,
          {
            'id': c.id,
            'event_id': c.event_id,
            'user_name': c.userName ?? '',
            'avatar': c.avatar ?? '',
            'description': c.description ?? '',
            'created': c.created.toIso8601String(),
            'image_url': c.imageUrl ?? '',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await db.close();
      print('💾 Comments saved to SQLite for event $eventId');
    } catch (e) {
      print('❌ Error saving comments to SQLite: $e');
    }
  }

  /// Refresh from Firebase in background
  void _refreshFirebaseInBackground(String eventId) async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) return;

    try {
      final firebaseComments = await _loadCommentsFromFirebase(eventId);
      if (firebaseComments.isNotEmpty) {
        _memoryCache.put(eventId, firebaseComments);
        await _saveCommentsLocally(eventId, firebaseComments);
        await _saveCommentsToSQLite(eventId, firebaseComments); // 🟢 CAMBIO
        print('♻️ Cache refreshed from Firebase');
      }
    } catch (_) {}
  }
}
