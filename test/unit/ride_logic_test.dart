import 'package:flutter_test/flutter_test.dart';
import 'package:gold_taxi/core/services/pricing_service.dart';
import 'package:gold_taxi/models/ride_status.dart';
import 'package:gold_taxi/features/map/data/repositories/mock_ride_repository.dart';

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
      final standard = PricingService.calculateEstimate(
        distanceInKm: distance,
        type: ServiceType.standard,
      );
      final comfort = PricingService.calculateEstimate(
        distanceInKm: distance,
        type: ServiceType.comfort,
      );
      final premium = PricingService.calculateEstimate(
        distanceInKm: distance,
        type: ServiceType.premium,
      );

      expect(comfort, closeTo(standard * 1.3, 0.1));
      expect(premium, closeTo(standard * 1.8, 0.1));
    });

    test('calculateEstimate applies surge multiplier correctly', () {
      const distance = 10.0;
      final base = PricingService.calculateEstimate(
        distanceInKm: distance,
        type: ServiceType.standard,
      );
      final surged = PricingService.calculateEstimate(
        distanceInKm: distance,
        type: ServiceType.standard,
        surgeMultiplier: 1.5,
      );
      expect(surged, closeTo(base * 1.5, 0.1));
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

  group('MockRideRepository Geofencing and Surge Tests', () {
    late MockRideRepository repository;

    setUp(() {
      repository = MockRideRepository();
    });

    test(
      'checkLocationInZone returns true for Kosice and false for Bratislava',
      () async {
        // Košice center: inside range
        final inKosice = await repository.checkLocationInZone(48.7219, 21.2575);
        expect(inKosice, isTrue);

        // Bratislava center: outside range
        final inBratislava = await repository.checkLocationInZone(
          48.1486,
          17.1077,
        );
        expect(inBratislava, isFalse);
      },
    );

    test(
      'getSurgeMultiplier returns 1.5 for city center and 1.0 outside',
      () async {
        // City center: inside range
        final surgeInCenter = await repository.getSurgeMultiplier(
          48.7219,
          21.2575,
        );
        expect(surgeInCenter, 1.5);

        // Outside center: outside range
        final surgeOutside = await repository.getSurgeMultiplier(
          48.7500,
          21.2000,
        );
        expect(surgeOutside, 1.0);
      },
    );
  });
}
