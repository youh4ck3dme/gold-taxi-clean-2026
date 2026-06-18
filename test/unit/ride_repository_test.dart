import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gold_taxi/features/map/data/repositories/mock_ride_repository.dart';
import 'package:gold_taxi/models/ride_model.dart';
import 'package:gold_taxi/models/ride_status.dart';
import 'package:gold_taxi/core/services/pricing_service.dart';

void main() {
  group('RideRepository Unit Tests (Mock)', () {
    late MockRideRepository repository;
    late RideModel testRide;

    setUp(() {
      repository = MockRideRepository();
      testRide = RideModel(
        id: 'test_ride_id',
        customerId: 'customer_123',
        pickupAddress: 'Pickup Loc',
        pickupLatLng: const LatLng(48.7219, 21.2575),
        dropoffAddress: 'Dropoff Loc',
        dropoffLatLng: const LatLng(48.7300, 21.2600),
        serviceType: ServiceType.standard,
        estimatedDistance: 1.5,
        estimatedDuration: 3.0,
        estimatedPrice: 3.50,
        status: RideStatus.requested,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    test('1. Create ride adds it to the requests queue', () async {
      final created = await repository.createRide(testRide);
      expect(created.id, testRide.id);

      final activeRequests = await repository.getActiveRequests().first;
      expect(activeRequests.any((r) => r.id == testRide.id), isTrue);
    });

    test('2. Accept succeeds only for requested ride without driver', () async {
      await repository.createRide(testRide);

      // Verify active queue has it
      var activeRequests = await repository.getActiveRequests().first;
      expect(activeRequests.any((r) => r.id == testRide.id), isTrue);

      // Accept the ride
      final acceptedRide = await repository.acceptRide(
        testRide.id,
        'driver_777',
      );
      expect(acceptedRide.driverId, 'driver_777');
      expect(acceptedRide.status, RideStatus.accepted);

      // Verify it is removed from the requested active queue
      activeRequests = await repository.getActiveRequests().first;
      expect(activeRequests.any((r) => r.id == testRide.id), isFalse);
    });

    test(
      '3. Second accept attempt fails (double-booking protection)',
      () async {
        await repository.createRide(testRide);

        // First accept succeeds
        await repository.acceptRide(testRide.id, 'driver_777');

        // Second accept throws "Ride is no longer available"
        expect(
          () => repository.acceptRide(testRide.id, 'driver_888'),
          throwsA(
            predicate((e) => e.toString().contains('no longer available')),
          ),
        );
      },
    );

    test(
      '4. getDriverActiveRide filters and streams driver active ride correctly',
      () async {
        await repository.createRide(testRide);

        // Before accept, no active ride for driver_777
        var activeRide = await repository
            .getDriverActiveRide('driver_777')
            .first;
        expect(activeRide, isNull);

        // Accept the ride
        await repository.acceptRide(testRide.id, 'driver_777');

        // Now driver_777 has testRide as active ride
        activeRide = await repository.getDriverActiveRide('driver_777').first;
        expect(activeRide, isNotNull);
        expect(activeRide!.id, testRide.id);
        expect(activeRide.status, RideStatus.accepted);

        // Update status to in progress
        await repository.updateRideStatus(testRide.id, RideStatus.inProgress);
        activeRide = await repository.getDriverActiveRide('driver_777').first;
        expect(activeRide!.status, RideStatus.inProgress);

        // Complete the ride -> should be cleared from driver active stream
        await repository.updateRideStatus(testRide.id, RideStatus.completed);
        activeRide = await repository.getDriverActiveRide('driver_777').first;
        expect(activeRide, isNull);
      },
    );
  });
}
