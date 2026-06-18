import 'package:flutter_test/flutter_test.dart';
import 'package:gold_taxi/models/driver_position_model.dart';
import 'package:gold_taxi/features/map/data/services/driver_profile_service.dart';

void main() {
  group('DriverProfileService Tests', () {
    group('DriverPositionModel Conversion Tests', () {
      test('DriverPositionModel toMap contains all required fields', () {
        final now = DateTime.now();
        final driver = DriverPositionModel(
          driverId: 'test_driver_001',
          name: 'Test Driver',
          avatar: 'https://example.com/avatar.png',
          lat: 48.1486,
          lng: 17.1077,
          bearing: 45.0,
          isAvailable: true,
          carModel: 'Škoda Octavia',
          carPlate: 'BA-123-XY',
          serviceType: 'Standard',
          rating: 4.8,
          phone: '+421 900 123 456',
          lastUpdated: now,
        );

        final map = driver.toMap();

        expect(map['display_name'], 'Test Driver');
        expect(map['current_lat'], 48.1486);
        expect(map['current_lng'], 17.1077);
        expect(map['bearing'], 45.0);
        expect(map['is_online'], true);
        expect(map['vehicle_type'], 'Škoda Octavia');
        expect(map['vehicle_plate'], 'BA-123-XY');
        expect(map['phone'], '+421 900 123 456');
      });

      test('DriverPositionModel fromMap creates correct instance', () {
        final now = DateTime.now().toIso8601String();
        final data = {
          'id': 'test_driver_001',
          'display_name': 'Test Driver',
          'current_lat': 48.1486,
          'current_lng': 17.1077,
          'bearing': 45.0,
          'is_online': true,
          'vehicle_type': 'Škoda Octavia',
          'vehicle_plate': 'BA-123-XY',
          'rating': 4.8,
          'phone': '+421 900 123 456',
          'updated_at': now,
        };

        final driver = DriverPositionModel.fromMap('test_driver_001', data);

        expect(driver.driverId, 'test_driver_001');
        expect(driver.name, 'Test Driver');
        expect(driver.carModel, 'Škoda Octavia');
        expect(driver.carPlate, 'BA-123-XY');
        expect(driver.rating, 4.8);
        expect(driver.lat, 48.1486);
        expect(driver.lng, 17.1077);
      });
    });

    group('Service Configuration Tests', () {
      test('DriverProfileService table name is correct', () {
        expect(DriverProfileService.tableName, 'drivers');
      });
    });

    group('Complete Driver Profile Tests', () {
      test('Can serialize and deserialize complete driver profile', () {
        final now = DateTime.now();
        final originalDriver = DriverPositionModel(
          driverId: 'driver_002',
          name: 'Peter Kováč',
          avatar: 'https://i.pravatar.cc/150?u=peter',
          lat: 48.1520,
          lng: 17.1100,
          bearing: 135.0,
          isAvailable: false,
          carModel: 'Volkswagen Passat',
          carPlate: 'KE-456-CD',
          serviceType: 'Premium',
          rating: 4.95,
          phone: '+421 910 111 222',
          lastUpdated: now,
        );

        final serialized = originalDriver.toMap();
        serialized['id'] = originalDriver.driverId;
        // Mock DB fields that aren't in toMap for tests
        serialized['rating'] = 4.95;

        final deserialized = DriverPositionModel.fromMap(
          originalDriver.driverId,
          serialized,
        );

        expect(deserialized.driverId, originalDriver.driverId);
        expect(deserialized.name, originalDriver.name);
        expect(deserialized.carModel, originalDriver.carModel);
        expect(deserialized.carPlate, originalDriver.carPlate);
        expect(deserialized.rating, 4.95);
        expect(deserialized.lat, originalDriver.lat);
        expect(deserialized.lng, originalDriver.lng);
      });
    });
  });
}
