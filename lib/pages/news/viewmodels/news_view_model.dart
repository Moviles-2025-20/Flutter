import 'package:flutter/material.dart';
import '../models/news.dart';
import '../../../util/news_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NewsViewModel extends ChangeNotifier {
  final NewsService _service = NewsService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<News> news = [];
  bool isLoading = false;
  String? error;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<void> loadNews() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _service.loadNews();

      if (result.isEmpty) {
        error = "No news available. Check your connection.";
      }

      news = result;
    } catch (e) {
      error = "Error loading news: $e";
    }

    isLoading = false;
    notifyListeners();
  }

Future<void> toggleLike(String id) async {
  final userId = currentUserId;
  if (userId == null) return;


  final index = news.indexWhere((n) => n.id == id);
  if (index == -1) return;

  final item = news[index];

  if (item.ratings.contains(userId)) {
    item.ratings.remove(userId);
  } else {
    item.ratings.add(userId);
  }

  notifyListeners(); 

  await _service.toggleLike(id);


  Future.delayed(const Duration(milliseconds: 350), () {
    loadNews();
  });
}
}

