import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lru_cache/lru_cache.dart';
import 'package:app_flutter/util/firebase_service.dart';

import '../pages/news/models/news.dart';


class NewsService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CacheManager _imageCache = DefaultCacheManager();

  final LruCache<String, List<News>> _memoryCache = LruCache(50);
  
  Future<List<News>> get list => loadNews();

  Future<List<News>> loadNews() async {
    final mem = await _memoryCache.get("news");
    if (mem != null) {
      return mem;
    }

    final news = await _loadFirebase();
    if (news.isNotEmpty) {
      await _memoryCache.put("news", news);
      return news;
    }

    
    return [];
  }

  Future<List<News>> _loadFirebase() async {
    try {
      final snapshot =
          await _firestore.collection("news").get();
      
      if (snapshot.docs.isEmpty) {
        return [];
      }
      List<News> list = [];
      for (var doc in snapshot.docs) {
        final event_id = doc.data()['event_id'] ?? '';
        if (event_id.isEmpty) {
          continue;
        }

        

        final name_event = await _firestore
            .collection("events")
            .doc(event_id)
            .get()
            .then((e) => e.data()?['name'] ?? 'Unknown Event 111111');
        list.add(News.fromJson(doc.id, {
          ...doc.data(),
          'event_name': name_event,
        }));
      }

      return list;
    } catch (e) {


      for (var n in await list) {
        if (n.photoUrl.isNotEmpty) {
          await _imageCache.downloadFile(n.photoUrl);
        }
      }

      return list;
    }
  }

  void _refreshFromFirebase() async {
    final conn = await Connectivity().checkConnectivity();
    if (conn == ConnectivityResult.none) return;

    final remote = await _loadFirebase();
    
  }


  Future<void> toggleLike(String newsId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final ref = _firestore.collection("news").doc(newsId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final List ratings = snap['ratings'] ?? [];



      if (ratings.contains(uid)) {
        tx.update(ref, {
          'ratings': FieldValue.arrayRemove([uid])
        });
      } else {
        tx.update(ref, {
          'ratings': FieldValue.arrayUnion([uid])
        });
      }
    });

    _refreshFromFirebase();
  }
}
