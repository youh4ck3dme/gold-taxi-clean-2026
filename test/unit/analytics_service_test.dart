import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:gold_taxi/core/services/analytics_service.dart';

class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

void main() {
  late MockFirebaseAnalytics mockAnalytics;
  late AnalyticsService analyticsService;

  setUp(() {
    mockAnalytics = MockFirebaseAnalytics();
    
    // Stub the default setAnalyticsCollectionEnabled call in constructor
    when(() => mockAnalytics.setAnalyticsCollectionEnabled(any()))
        .thenAnswer((_) async {});
  });

  group('AnalyticsService tests', () {
    test('Constructor initializes analytics and sets collection enabled when enabled', () {
      analyticsService = AnalyticsService(analytics: mockAnalytics, isEnabled: true);
      verify(() => mockAnalytics.setAnalyticsCollectionEnabled(true)).called(1);
    });

    test('logEvent logs event when enabled', () async {
      analyticsService = AnalyticsService(analytics: mockAnalytics, isEnabled: true);
      
      when(() => mockAnalytics.logEvent(
            name: any(named: 'name'),
            parameters: any(named: 'parameters'),
          )).thenAnswer((_) async {});

      await analyticsService.logEvent(
        name: 'test_event',
        parameters: {'key': 'value'},
      );

      verify(() => mockAnalytics.logEvent(
            name: 'test_event',
            parameters: {'key': 'value'},
          )).called(1);
    });

    test('logEvent does not call FirebaseAnalytics when disabled', () async {
      analyticsService = AnalyticsService(analytics: mockAnalytics, isEnabled: false);
      
      // Reset mocks to clear constructor call count check
      reset(mockAnalytics);

      await analyticsService.logEvent(
        name: 'test_event',
        parameters: {'key': 'value'},
      );

      verifyNever(() => mockAnalytics.logEvent(
            name: any(named: 'name'),
            parameters: any(named: 'parameters'),
          ));
    });

    test('logRideRequested logs correct properties', () async {
      analyticsService = AnalyticsService(analytics: mockAnalytics, isEnabled: true);
      
      when(() => mockAnalytics.logEvent(
            name: any(named: 'name'),
            parameters: any(named: 'parameters'),
          )).thenAnswer((_) async {});

      await analyticsService.logRideRequested(
        rideId: 'ride_123',
        estimatedPrice: 15.50,
        stopCount: 2,
        vehicleType: 'Premium',
      );

      verify(() => mockAnalytics.logEvent(
            name: 'Ride_Requested',
            parameters: {
              'ride_id': 'ride_123',
              'estimated_price': 15.50,
              'stop_count': 2,
              'vehicle_type': 'Premium',
            },
          )).called(1);
    });

    test('logPaymentFailed logs correct properties', () async {
      analyticsService = AnalyticsService(analytics: mockAnalytics, isEnabled: true);
      
      when(() => mockAnalytics.logEvent(
            name: any(named: 'name'),
            parameters: any(named: 'parameters'),
          )).thenAnswer((_) async {});

      await analyticsService.logPaymentFailed(
        rideId: 'ride_123',
        amount: 25.00,
        method: 'stripe',
        errorReason: 'card_declined',
      );

      verify(() => mockAnalytics.logEvent(
            name: 'Payment_Failed',
            parameters: {
              'ride_id': 'ride_123',
              'amount': 25.00,
              'method': 'stripe',
              'error_reason': 'card_declined',
            },
          )).called(1);
    });
  });
}
