// lib/util/analytics_service.dart
import 'package:firebase_analytics/firebase_analytics.dart';

enum DiscoveryMethod { wishMeLuck, manualBrowse }

class AnalyticsService {
  // Singleton
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  

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

  Future<void> logWeeklyChallengeUsed(String userId) async {
    await _analytics.logEvent(
      name: 'weekly_challenge_used',
      parameters: {
        'user_id': userId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
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
  void activarFirebase() async{
    await _analytics.setAnalyticsCollectionEnabled(true);
  }


  // Observer para navigation
  FirebaseAnalyticsObserver getAnalyticsObserver(){
    return FirebaseAnalyticsObserver(analytics: _analytics);
  }
}