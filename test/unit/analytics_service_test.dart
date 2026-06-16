import 'package:flutter_test/flutter_test.dart';
import 'package:gold_taxi/core/services/analytics_service.dart';

void main() {
  late AnalyticsService analyticsService;

  group('AnalyticsService Unit Tests', () {
    test('Constructor initializes correctly with default parameters', () {
      analyticsService = AnalyticsService();
      expect(analyticsService.isEnabled, isTrue);
    });

    test('Constructor initializes correctly with custom parameters', () {
      analyticsService = AnalyticsService(isEnabled: false);
      expect(analyticsService.isEnabled, isFalse);
    });

    test('logEvent completes successfully', () async {
      analyticsService = AnalyticsService();
      await expectLater(
        analyticsService.logEvent(
          name: 'test_event',
          parameters: {'key': 'value'},
        ),
        completes,
      );
    });

    test('logRideRequested completes successfully', () async {
      analyticsService = AnalyticsService();
      await expectLater(
        analyticsService.logRideRequested(
          rideId: 'ride_123',
          estimatedPrice: 15.50,
          stopCount: 2,
          vehicleType: 'Premium',
        ),
        completes,
      );
    });

    test('logPaymentFailed completes successfully', () async {
      analyticsService = AnalyticsService();
      await expectLater(
        analyticsService.logPaymentFailed(
          rideId: 'ride_123',
          amount: 25.00,
          method: 'stripe',
          errorReason: 'card_declined',
        ),
        completes,
      );
    });

    test('recordError completes successfully', () async {
      analyticsService = AnalyticsService();
      await expectLater(
        analyticsService.recordError(
          Exception('Test error'),
          StackTrace.current,
          reason: 'Testing exception logging',
        ),
        completes,
      );
    });
  });
}
