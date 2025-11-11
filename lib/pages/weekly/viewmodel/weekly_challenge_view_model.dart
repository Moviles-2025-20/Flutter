import 'dart:math';
import 'package:app_flutter/pages/events/model/comment.dart';
import 'package:app_flutter/util/comment_service.dart';
import 'package:app_flutter/pages/events/model/event.dart';
import 'package:app_flutter/util/event_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app_flutter/util/analytics_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';


class WeeklyChallengeViewModel extends ChangeNotifier {
  final EventsService _eventsService = EventsService();
  final CommentService _commentService = CommentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AnalyticsService _analyticsService = AnalyticsService();
  String? _error;
  String? get error => _error;

  int _completedCount = 0;
  bool _isLoadingStats = false;
  int get completedCount => _completedCount;
  bool get isLoadingStats => _isLoadingStats;

  Event? _weeklyEvent;
  List<Comment> _comments = [];
  bool _isLoading = false;
  String? _errorMessage;

  Event? get weeklyEvent => _weeklyEvent;
  List<Comment> get comments => _comments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;


  Future<void> loadWeeklyChallenge() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
    final hasInternet = connectivity != ConnectivityResult.none;
    if (!hasInternet) {
      debugPrint("Sin conexión.");
      _error = "No connection for the weekly challenge.";
      notifyListeners();
      

      return;
    }
      _isLoading = true;
      _errorMessage = null;
      _error = null;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }


      final allEvents = await _eventsService.getEvents();


      final now = DateTime.now();
      final startOfWeek =
          now.subtract(Duration(days: now.weekday - 1)); // lunes
      final endOfWeek = startOfWeek.add(const Duration(days: 6)); // domingo

      final weeklyEvents = allEvents.where((event) {
        return event.created.isAfter(startOfWeek) &&
               event.created.isBefore(endOfWeek);
      }).toList();

      if (weeklyEvents.isEmpty) {
        _errorMessage = "No events available for this week.";
        _isLoading = false;
        notifyListeners();
        return;
      }

      
      final random = Random();
      _weeklyEvent = weeklyEvents[random.nextInt(weeklyEvents.length)];

      // Traer comentarios del evento
      _comments = await _commentService.loadComments(_weeklyEvent!.id);

    } catch (e) {
      _errorMessage = "Error loading weekly challenge: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    await loadUserWeeklyChallengeStats();
  }

  Future<void> loadUserWeeklyChallengeStats() async {
  final user = _auth.currentUser;
  if (user == null) return;

  try {
    

    _isLoadingStats = true;
    notifyListeners();

    final count = await _analyticsService.getWeeklyChallengesCompletedLast30Days(user.uid);
    _completedCount = count;
  } catch (e) {
    debugPrint("Error loading weekly challenge stats: $e");
    _completedCount = 0;
  } finally {
    _isLoadingStats = false;
    notifyListeners();
  }
}
}