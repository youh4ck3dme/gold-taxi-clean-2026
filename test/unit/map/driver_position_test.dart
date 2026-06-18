import 'package:flutter_test/flutter_test.dart';
import 'package:gold_taxi/models/driver_position_model.dart';
import 'package:gold_taxi/features/map/data/repositories/driver_position_repository.dart';

void main() {
  group('DriverPositionModel Tests', () {
    test('DriverPositionModel has correct fields', () {
      final driver = DriverPositionModel(
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
        lastUpdated: DateTime.now(),
      );

      expect(driver.driverId, 'demo_driver_jan_novak');
      expect(driver.name, 'Ján Novák');
      expect(driver.carModel, 'Škoda Octavia');
      expect(driver.carPlate, 'BA-123GT');
      expect(driver.rating, 4.9);
      expect(driver.isAvailable, true);
      expect(driver.lat, 48.1486);
      expect(driver.lng, 17.1077);
    });

    test('DriverPositionModel fromMap creates correct instance', () {
      final data = {
        'display_name': 'Ján Novák',
        'avatar': 'https://i.pravatar.cc/150?u=jan_novak',
        'current_lat': 48.1486,
        'current_lng': 17.1077,
        'bearing': 45.0,
        'is_online': true,
        'vehicle_type': 'Škoda Octavia',
        'vehicle_plate': 'BA-123GT',
        'serviceType': 'Standard',
        'rating': 4.9,
        'phone': '+421 905 123 456',
        'updated_at': DateTime.now().toIso8601String(),
      };

      final driver = DriverPositionModel.fromMap('demo_driver_jan_novak', data);

      expect(driver.driverId, 'demo_driver_jan_novak');
      expect(driver.name, 'Ján Novák');
      expect(driver.carModel, 'Škoda Octavia');
      expect(driver.carPlate, 'BA-123GT');
      expect(driver.rating, 4.9);
      expect(driver.lat, 48.1486);
      expect(driver.lng, 17.1077);
    });

    test('DriverPositionModel toMap serializes correctly', () {
      final driver = DriverPositionModel(
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
        lastUpdated: DateTime.now(),
      );

      final map = driver.toMap();

      expect(map['display_name'], 'Ján Novák');
      expect(map['vehicle_type'], 'Škoda Octavia');
      expect(map['vehicle_plate'], 'BA-123GT');
      expect(map['current_lat'], 48.1486);
      expect(map['current_lng'], 17.1077);
    });

    test('DriverPositionModel equality works correctly', () {
      final now = DateTime.now();
      final driver1 = DriverPositionModel(
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

      final driver2 = DriverPositionModel(
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

      expect(driver1, driver2);
    });
  });

  group('DriverPositionRepository Tests', () {
    late DriverPositionRepository repository;

    setUp(() {
      repository = DriverPositionRepository();
    });

    tearDown(() {
      repository.dispose();
    });

    test('Repository contains demo driver Ján Novák', () async {
      final drivers = await repository.getNearestDrivers(
        lat: 48.1486,
        lng: 17.1077,
        limit: 10,
        maxDistanceKm: 1.0,
      );

      final janNovakIndex = drivers.indexWhere(
        (d) => d.driverId == 'demo_driver_jan_novak',
      );

      expect(janNovakIndex, isNot(-1));
      final janNovak = drivers[janNovakIndex];
      expect(janNovak.name, 'Ján Novák');
      expect(janNovak.carModel, 'Škoda Octavia');
      expect(janNovak.carPlate, 'BA-123GT');
      expect(janNovak.rating, 4.9);
      expect(janNovak.isAvailable, true);
      expect(janNovak.lat, 48.1486);
      expect(janNovak.lng, 17.1077);
    });

    test(
      'Repository streams both Ján Novák (online) and Peter Horváth (offline)',
      () async {
        final allDrivers = await repository.getDriverPositionsStream().first;

        final jan = allDrivers.firstWhere(
          (d) => d.driverId == 'demo_driver_jan_novak',
        );
        expect(jan.isAvailable, isTrue);
        expect(jan.name, 'Ján Novák');

        final peter = allDrivers.firstWhere(
          (d) => d.driverId == 'demo_driver_peter_horvath',
        );
        expect(peter.isAvailable, isFalse);
        expect(peter.name, 'Peter Horváth');
      },
    );
  });
}
