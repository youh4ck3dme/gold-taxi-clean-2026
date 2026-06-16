import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gold_taxi/models/ride_model.dart';
import 'package:gold_taxi/models/ride_status.dart';
import 'package:gold_taxi/core/services/pricing_service.dart';

void main() {
  group('RideModel Tests', () {
    final mockRide = RideModel(
      id: '123',
      customerId: 'user_1',
      pickupAddress: 'Aupark',
      pickupLatLng: const LatLng(48.7188, 21.2614),
      dropoffAddress: 'Airport',
      dropoffLatLng: const LatLng(48.6631, 21.2403),
      serviceType: ServiceType.standard,
      estimatedDistance: 10.5,
      estimatedDuration: 15.0,
      estimatedPrice: 12.5,
      status: RideStatus.requested,
      createdAt: DateTime(2026, 6, 14, 12, 0).toUtc(),
      updatedAt: DateTime(2026, 6, 14, 12, 0).toUtc(),
    );

    test('toJson and fromJson should be consistent', () {
      final json = mockRide.toJson();
      final fromJson = RideModel.fromJson(json);
      expect(fromJson, mockRide);
    });

    test('Mapping from/to DB columns (snake_case)', () {
      final json = mockRide.toJson();
      expect(json['customer_id'], 'user_1');
      expect(json['pickup_lat'], 48.7188);
      expect(json['status'], 'requested');
      expect(json['estimated_distance_km'], 10.5);
    });

    test('toDbJson should remove stops and sanitize driver_id', () {
      final dbJson = mockRide.toDbJson();
      expect(dbJson.containsKey('stops'), isFalse);

      final rideWithMockDriver = mockRide.copyWith(driverId: 'demo_driver_jan_novak');
      final dbJsonMockDriver = rideWithMockDriver.toDbJson();
      expect(dbJsonMockDriver['driver_id'], isNull);

      const validUuid = 'd3b07384-d113-49c3-a55e-2e0e5a6f272a';
      final rideWithRealDriver = mockRide.copyWith(driverId: validUuid);
      final dbJsonRealDriver = rideWithRealDriver.toDbJson();
      expect(dbJsonRealDriver['driver_id'], validUuid);
    });
  });
}
