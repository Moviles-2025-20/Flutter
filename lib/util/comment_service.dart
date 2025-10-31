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

class CommentService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// LruCache<String, List<Comment>> — usamos put/get en lugar de operadores []
  final LruCache<String, List<Comment>> _memoryCache =
      LruCache<String, List<Comment>>(50);

  final CacheManager _imageCache = DefaultCacheManager();

  /// Load comments with priority: memory -> local -> firebase
  Future<List<Comment>> loadComments(String eventId) async {
    // 1) Try memory cache via get()
    try {
      final mem = await _memoryCache.get(eventId);
      if (mem != null && mem.isNotEmpty) {
        print('⚡ Loaded comments from LRU memory cache');
        return mem;
      }
    } catch (e) {
      // si get no existe en la versión del paquete, podrías usar otro método del package
      // o reemplazar LruCache por un Map/LinkedHashMap con lógica LRU propia.
    }

    // 2) Try local storage
    final localComments = await _loadCommentsFromLocal(eventId);
    if (localComments.isNotEmpty) {
      print('Loaded comments from local cache');
      // Guardar en memoria LRU usando put
      try {
        _memoryCache.put(eventId, localComments);
      } catch (_) {}
      // refrescar en background desde Firebase
      _refreshFirebaseInBackground(eventId);
      return localComments;
    }

    // 3) Try Firebase if online
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity != ConnectivityResult.none) {
      final firebaseComments = await _loadCommentsFromFirebase(eventId);
      if (firebaseComments.isNotEmpty) {
        print(' Loaded comments from Firebase');
        try {
          _memoryCache.put(eventId, firebaseComments);
        } catch (_) {}
        await _saveCommentsLocally(eventId, firebaseComments);
        return firebaseComments;
      }
    }

    print(' No comments found locally or remotely');
    return [];
  }

  /// Load from Firebase (collection 'comments' filtered by eventId)
  Future<List<Comment>> _loadCommentsFromFirebase(String eventId) async {
    try {
      final query = _firestore
          .collection("comments")
          .where("eventId", isEqualTo: eventId)
          .orderBy("created", descending: true)
          .limit(100);

      final snapshot = await query.get();

      final comments = snapshot.docs.map((doc) {
        final data = doc.data();
        return Comment.fromJson(doc.id, data);
      }).toList();

      // cachear imágenes en disco (opcional)
      for (var c in comments) {
        if (c.imageUrl != null && c.imageUrl!.isNotEmpty) {
          try {
            await _imageCache.downloadFile(c.imageUrl!);
          } catch (_) {}
        }
      }

      return comments;
    } catch (e) {
      print(" Error loading Firebase comments: $e");
      return [];
    }
  }

  /// Load cached comments from local file (comments_cache.json)
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
      print(" Error reading local comments: $e");
      return [];
    }
  }

  /// Save comments to local cache file (merges by event)
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

      // remove old comments for same event
      allComments.removeWhere((c) => c["eventId"] == eventId);

      // add new ones
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
      print(" Comments saved to local cache");
    } catch (e) {
      print(" Error saving comments locally: $e");
    }
  }

  /// When we have local data, refresh silently from Firebase
  void _refreshFirebaseInBackground(String eventId) async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) return;

    try {
      final firebaseComments = await _loadCommentsFromFirebase(eventId);
      if (firebaseComments.isNotEmpty) {
        try {
          _memoryCache.put(eventId, firebaseComments);
        } catch (_) {}
        await _saveCommentsLocally(eventId, firebaseComments);
        print(' Cache refreshed from Firebase');
      }
    } catch (_) {}
  }
}
