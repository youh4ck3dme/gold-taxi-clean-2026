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
        'name': 'Ján Novák',
        'avatar': 'https://i.pravatar.cc/150?u=jan_novak',
        'lat': 48.1486,
        'lng': 17.1077,
        'bearing': 45.0,
        'isAvailable': true,
        'carModel': 'Škoda Octavia',
        'carPlate': 'BA-123GT',
        'serviceType': 'Standard',
        'rating': 4.9,
        'phone': '+421 905 123 456',
        'lastUpdated': DateTime.now().toIso8601String(),
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

      expect(map['name'], 'Ján Novák');
      expect(map['carModel'], 'Škoda Octavia');
      expect(map['carPlate'], 'BA-123GT');
      expect(map['rating'], 4.9);
      expect(map['lat'], 48.1486);
      expect(map['lng'], 17.1077);
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
      // Test through getNearestDrivers which uses the internal driver list
      final drivers = await repository.getNearestDrivers(
        lat: 48.1486,
        lng: 17.1077,
        limit: 10,
        maxDistanceKm: 1.0,
      );
      
      final janNovakIndex = drivers.indexWhere((d) => d.driverId == 'demo_driver_jan_novak');
      
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

    test('Repository has Bratislava center coordinates for demo driver', () async {
      final drivers = await repository.getNearestDrivers(
        lat: 48.1486,
        lng: 17.1077,
        limit: 1,
        maxDistanceKm: 1.0,
      );

      expect(drivers.isNotEmpty, true);
      
      final firstDriver = drivers.first;
      expect(firstDriver.lat, 48.1486);
      expect(firstDriver.lng, 17.1077);
    });

    test('Demo driver has correct status online', () async {
      final drivers = await repository.getNearestDrivers(
        lat: 48.1486,
        lng: 17.1077,
        limit: 1,
      );

      expect(drivers.isNotEmpty, true);
      expect(drivers.first.isAvailable, true);
    });
  });
}
