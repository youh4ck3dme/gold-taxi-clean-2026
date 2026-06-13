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

        expect(map['name'], 'Test Driver');
        expect(map['avatar'], 'https://example.com/avatar.png');
        expect(map['lat'], 48.1486);
        expect(map['lng'], 17.1077);
        expect(map['bearing'], 45.0);
        expect(map['isAvailable'], true);
        expect(map['carModel'], 'Škoda Octavia');
        expect(map['carPlate'], 'BA-123-XY');
        expect(map['serviceType'], 'Standard');
        expect(map['rating'], 4.8);
        expect(map['phone'], '+421 900 123 456');
      });

      test('DriverPositionModel fromMap creates correct instance', () {
        final now = DateTime.now().toIso8601String();
        final data = {
          'id': 'test_driver_001',
          'name': 'Test Driver',
          'avatar': 'https://example.com/avatar.png',
          'lat': 48.1486,
          'lng': 17.1077,
          'bearing': 45.0,
          'isAvailable': true,
          'carModel': 'Škoda Octavia',
          'carPlate': 'BA-123-XY',
          'serviceType': 'Standard',
          'rating': 4.8,
          'phone': '+421 900 123 456',
          'lastUpdated': now,
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
        expect(DriverProfileService.tableName, 'driver_profiles');
      });
    });

    group('Complete Driver Profile Tests', () {
      test('Can create complete driver profile model', () {
        final now = DateTime.now();
        
        // Complete driver profile matching requirements
        final janNovak = DriverPositionModel(
          driverId: 'demo_driver_jan_novak',
          name: 'Ján Novák',
          avatar: 'https://i.pravatar.cc/150?u=jan_novak',
          lat: 48.1486,
          lng: 17.1077,
          bearing: 45.0,
          isAvailable: true,
          carModel: 'Škoda Octavia',
          carPlate: 'BA-123GT',
          serviceType: 'Standard',
          rating: 4.9,
          phone: '+421 905 123 456',
          lastUpdated: now,
        );

        // Verify all fields are correct
        expect(janNovak.driverId, 'demo_driver_jan_novak');
        expect(janNovak.name, 'Ján Novák');
        expect(janNovak.carModel, 'Škoda Octavia');
        expect(janNovak.carPlate, 'BA-123GT');
        expect(janNovak.rating, 4.9);
        expect(janNovak.isAvailable, true);
        expect(janNovak.lat, 48.1486);
        expect(janNovak.lng, 17.1077);

        // Verify it can be serialized
        final map = janNovak.toMap();
        expect(map, isA<Map<String, dynamic>>());
        expect(map.length, greaterThan(0));
      });

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
        
        final deserialized = DriverPositionModel.fromMap(
          originalDriver.driverId,
          serialized,
        );

        expect(deserialized.driverId, originalDriver.driverId);
        expect(deserialized.name, originalDriver.name);
        expect(deserialized.carModel, originalDriver.carModel);
        expect(deserialized.carPlate, originalDriver.carPlate);
        expect(deserialized.rating, originalDriver.rating);
        expect(deserialized.lat, originalDriver.lat);
        expect(deserialized.lng, originalDriver.lng);
      });
    });
  });
}
