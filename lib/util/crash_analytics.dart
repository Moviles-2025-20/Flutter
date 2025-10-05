import 'package:app_flutter/util/analytics_service.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class CrashTracker {
  final AnalyticsService _analytics = AnalyticsService();
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  Future<void> initializeCrashlytics() async {
    // Enable crash collection
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    
    // Log device info
    await _logDeviceInfo();
  }

  Future<void> _logDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      await _crashlytics.setCustomKey('device_model', androidInfo.model);
      await _crashlytics.setCustomKey('os_version', androidInfo.version.release);
      await _crashlytics.setCustomKey('device_type', 'Android');
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      await _crashlytics.setCustomKey('device_model', iosInfo.model);
      await _crashlytics.setCustomKey('os_version', iosInfo.systemVersion);
      await _crashlytics.setCustomKey('device_type', 'iOS');
    }
  }

  // Log non-fatal errors
  Future<void> logError(dynamic error, StackTrace? stackTrace) async {
    await _crashlytics.recordError(error, stackTrace);

    await _analytics.logError(error, stackTrace, Platform.operatingSystem);
   
  }
}