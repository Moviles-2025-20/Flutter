import 'package:flutter/material.dart';
import '../models/news.dart';
import '../../../util/news_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../util/local_DB_service.dart';

class NewsViewModel extends ChangeNotifier {
  final NewsService _service = NewsService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalUserService _localDb = LocalUserService();


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

    if (result.isNotEmpty) {
      news = result;
      await _localDb.saveNews(result);
    } else {
      news = await _localDb.getAllNews();
      if (news.isEmpty) {
        error = "No news available.";
      }
    }
  } catch (e) {
    news = await _localDb.getAllNews();

    if (news.isEmpty) {
      error = "Error loading news: $e";
    }
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

