import 'package:flutter_test/flutter_test.dart';
import 'package:gold_taxi/core/services/pricing_service.dart';
import 'package:gold_taxi/models/ride_status.dart';

void main() {
  group('PricingService Tests', () {
    test('calculateEstimate returns minimum fare for short distances', () {
      final estimate = PricingService.calculateEstimate(
        distanceInKm: 0.5,
        type: ServiceType.standard,
      );
      expect(estimate, PricingService.minimumFare);
    });

    test('calculateEstimate applies service multipliers correctly', () {
      const distance = 10.0;
      final standard = PricingService.calculateEstimate(distanceInKm: distance, type: ServiceType.standard);
      final comfort = PricingService.calculateEstimate(distanceInKm: distance, type: ServiceType.comfort);
      final premium = PricingService.calculateEstimate(distanceInKm: distance, type: ServiceType.premium);

      expect(comfort, closeTo(standard * 1.3, 0.1));
      expect(premium, closeTo(standard * 1.8, 0.1));
    });
  });

  group('RideStatus State Machine Logic', () {
    test('canCancel returns true only for early stages', () {
      expect(RideStatus.requested.canCancel, isTrue);
      expect(RideStatus.accepted.canCancel, isTrue);
      expect(RideStatus.driverArriving.canCancel, isTrue);
      expect(RideStatus.inProgress.canCancel, isFalse);
      expect(RideStatus.completed.canCancel, isFalse);
      expect(RideStatus.cancelled.canCancel, isFalse);
    });
  });
}
