import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class AnalyticsService {
  final FirebaseAnalytics? analytics;
  final bool isEnabled;

  AnalyticsService({
    this.analytics,
    this.isEnabled = true,
  }) {
    _init();
  }

  void _init() {
    if (isEnabled && analytics != null) {
      analytics!.setAnalyticsCollectionEnabled(true);
      debugPrint('📊 Firebase Analytics initialized and enabled.');
    } else {
      debugPrint('📊 Firebase Analytics is disabled or Firebase not initialized.');
    }
  }

  /// Log a custom event to Firebase Analytics with safety checks.
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (!isEnabled || analytics == null) {
      debugPrint('📊 [Mock Analytics] Event: $name, Params: $parameters');
      return;
    }
    try {
      await analytics!.logEvent(name: name, parameters: parameters);
      debugPrint('📊 [Firebase Analytics] Logged Event: $name');
    } catch (e, stack) {
      debugPrint('⚠️ Analytics: Failed to log event $name: $e');
      await recordError(e, stack, reason: 'Failed to log event $name');
    }
  }

  /// Log when a ride request is made.
  Future<void> logRideRequested({
    required String rideId,
    required double estimatedPrice,
    required int stopCount,
    required String vehicleType,
  }) async {
    await logEvent(
      name: 'Ride_Requested',
      parameters: {
        'ride_id': rideId,
        'estimated_price': estimatedPrice,
        'stop_count': stopCount,
        'vehicle_type': vehicleType,
      },
    );
  }

  /// Log when a payment fails.
  Future<void> logPaymentFailed({
    required String rideId,
    required double amount,
    required String method,
    required String errorReason,
  }) async {
    await logEvent(
      name: 'Payment_Failed',
      parameters: {
        'ride_id': rideId,
        'amount': amount,
        'method': method,
        'error_reason': errorReason,
      },
    );
  }

  /// Record error to Firebase Crashlytics or debug console if disabled.
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    bool fatal = false,
  }) async {
    if (kDebugMode) {
      debugPrint('🔴 [Crashlytics Error] Exception: $exception');
      if (stack != null) debugPrint(stack.toString());
    }

    try {
      if (FirebaseCrashlytics.instance.isCrashlyticsCollectionEnabled) {
        await FirebaseCrashlytics.instance.recordError(
          exception,
          stack,
          reason: reason,
          fatal: fatal,
        );
      }
    } catch (e) {
      debugPrint('⚠️ Crashlytics error submission failed: $e');
    }
  }
}
