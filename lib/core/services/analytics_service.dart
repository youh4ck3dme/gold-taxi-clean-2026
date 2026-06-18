import 'package:flutter/foundation.dart';

class AnalyticsService {
  final bool isEnabled;

  AnalyticsService({dynamic analytics, this.isEnabled = true}) {
    _init();
  }

  void _init() {
    debugPrint('📊 Analytics initialized (No Firebase).');
  }

  /// Log a custom event
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    debugPrint('📊 [Analytics] Event: $name, Params: $parameters');
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

  /// Record error to debug console.
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    bool fatal = false,
  }) async {
    debugPrint('🔴 [Error Record] Exception: $exception');
    if (reason != null) debugPrint('Reason: $reason');
    if (stack != null) debugPrint(stack.toString());
  }
}
