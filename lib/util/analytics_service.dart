// lib/util/analytics_service.dart
import 'package:app_flutter/util/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';


enum DiscoveryMethod { wishMeLuck, manualBrowse }

class AnalyticsService {
  // Singleton
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final firestore = FirebaseService.firestore;
  

  // Discovery Methods
  Future<void> logDiscoveryMethod(DiscoveryMethod method) async {

    await _analytics.logEvent(
      name: 'activity_discovery_method',
      parameters: {
        'method': method == DiscoveryMethod.wishMeLuck 
            ? 'wish_me_luck' 
            : 'manual_browse',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  Future<void> logActivitySelection({
    required String activityId,
    required DiscoveryMethod discoveryMethod,
  }) async {
    await _analytics.logEvent(
      name: 'activity_selected',
      parameters: {
        'activity_id': activityId,
        'discovery_method': discoveryMethod == DiscoveryMethod.wishMeLuck 
            ? 'wish_me_luck' 
            : 'manual_browse',
      },
    );
  }

  // Wish Me Luck specific
  Future<void> logWishMeLuckUsed(String userId) async {
    await _analytics.logEvent(
      name: 'wish_me_luck_used',
      parameters: {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  //Enter the map feature
  Future<void> logMapUsed(String userId) async {
    print("Generando evento de mapa=============================================================================================================");
    await _analytics.logEvent(
      name: 'map_view_opened',
      parameters: {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }


  // Weekly Challenge specific
  Future<void> logWeeklyChallengeCompleted(String userId, String challengeId) async {
    final now = DateTime.now();

    
    await _analytics.logEvent(
      name: 'weekly_challenge_completed',
      parameters: {
        'user_id': userId,
        'challenge_id': challengeId,
        'timestamp': now.millisecondsSinceEpoch,
      },
    );

    
    await firestore.collection('weekly_challenge_completions').add({
      'user_id': userId,
      'challenge_id': challengeId,
      'timestamp': now,
    });

    await firestore.collection('user_activities').add(
      {
        'user_id': userId,
        'event_id': challengeId,
        'time': now,
        'source': "manual",
        'type' : "weekly challenge",
        "with_friends": false,
      }
    );
  }



  Future<int> getWeeklyChallengesCompletedLast30Days(String userId) async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final querySnapshot = await firestore
      .collection('weekly_challenge_completions')
      .where('user_id', isEqualTo: userId)
      .get();

    final filtered = querySnapshot.docs.where((doc) {
    final ts = (doc['timestamp'] as Timestamp).toDate();
    return ts.isAfter(thirtyDaysAgo);
  }).toList();


    return filtered.length;
  }

  

  //Percentage of outdoor indoor
  Future<void> logOutdoorIndoorActivity(int indoorOutdoorScore) async {
    
    await _analytics.logEvent(
        name: "outdoor_indoor_preference",
        parameters: {
          "percentage": indoorOutdoorScore,
        },
      );
  }

  // User properties
  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }

  // Screen tracking
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenName,
    );
  }

  Future<void> logError(dynamic error, StackTrace? stackTrace, String operatingSystem) async {
    
    await _analytics.logEvent(
      name: 'app_exception',
      parameters: {
        'error_type': error.runtimeType.toString(),
        'platform': operatingSystem,
      },
    );
  }

  Future<void> logCheckIn(String activityId, String category) async {
    await _analytics.logEvent(
      name: 'activity_check_in',
      parameters: {
        'activity_id': activityId,
        'category': category,
      },
    );
  }

  Future<void> logDirectionsRequested(String eventId, String userId) async {
    await _analytics.logEvent(
      name: 'directions_requested',
      parameters: {
        'user_id': userId,
        'event_id': eventId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Quiz analytics
  Future<void> logMoodQuizOpened() async {
    await _analytics.logEvent(
      name: 'mood_quiz_opened',
      parameters: {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  Future<void> logMoodQuizCompleted() async {
    await _analytics.logEvent(
      name: 'mood_quiz_completed',
      parameters: {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  void activarFirebase() async{
    await _analytics.setAnalyticsCollectionEnabled(true);
  }


  // Observer para navigation
  FirebaseAnalyticsObserver getAnalyticsObserver(){
    return FirebaseAnalyticsObserver(analytics: _analytics);
  }
}