import 'dart:async';
import 'dart:math';
import 'package:logger/logger.dart';
import '../../../../models/driver_position_model.dart';

/// Repository for managing driver positions.
/// Currently uses in-memory mock data. Replace _mockDrivers with
/// Supabase Realtime calls when the driver_positions table is ready.
class DriverPositionRepository {
  final Logger _logger = Logger();

  // In-memory store so stream updates work without a backend connection.
  final List<DriverPositionModel> _mockDrivers = [
    // Demo driver profile as specified in requirements
    DriverPositionModel(
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
    ),
    DriverPositionModel(
      driverId: 'driver_2',
      name: 'Peter Kováč',
      avatar: 'https://i.pravatar.cc/150?u=2',
      lat: 48.1520,
      lng: 17.1100,
      bearing: 135.0,
      isAvailable: true,
      carModel: 'Volkswagen Passat',
      carPlate: 'KE-456-CD',
      serviceType: 'Premium',
      rating: 4.9,
      phone: '+421 910 111 222',
      lastUpdated: DateTime.now(),
    ),
    DriverPositionModel(
      driverId: 'driver_3',
      name: 'Martin Horváth',
      avatar: 'https://i.pravatar.cc/150?u=3',
      lat: 48.1450,
      lng: 17.1050,
      bearing: 225.0,
      isAvailable: false,
      carModel: 'Toyota Corolla',
      carPlate: 'BA-789-EF',
      serviceType: 'Business',
      rating: 4.7,
      phone: '+421 907 333 444',
      lastUpdated: DateTime.now(),
    ),
    DriverPositionModel(
      driverId: 'driver_4',
      name: 'Lucia Varga',
      avatar: 'https://i.pravatar.cc/150?u=4',
      lat: 48.1550,
      lng: 17.1150,
      bearing: 315.0,
      isAvailable: true,
      carModel: 'Ford Focus',
      carPlate: 'PO-321-GH',
      serviceType: 'Eco',
      rating: 4.6,
      phone: '+421 908 555 666',
      lastUpdated: DateTime.now(),
    ),
  ];

  // StreamController so we can push updates to listeners.
  late final StreamController<List<DriverPositionModel>> _allController =
      StreamController<List<DriverPositionModel>>.broadcast()
        ..add(List.from(_mockDrivers));

  late final StreamController<List<DriverPositionModel>> _availableController =
      StreamController<List<DriverPositionModel>>.broadcast()
        ..add(_availableDrivers);

  List<DriverPositionModel> get _availableDrivers =>
      _mockDrivers.where((d) => d.isAvailable).toList();

  void _pushUpdates() {
    _allController.add(List.from(_mockDrivers));
    _availableController.add(_availableDrivers);
  }

  /// Stream of all driver positions (realtime-like updates).
  Stream<List<DriverPositionModel>> getDriverPositionsStream() {
    _logger.i('📡 Listening to driver positions (mock)…');
    return _allController.stream;
  }

  /// Stream of available drivers only.
  Stream<List<DriverPositionModel>> getAvailableDriversStream() {
    return _availableController.stream;
  }

  /// Update a driver's position in the local store.
  Future<void> updateDriverPosition(DriverPositionModel position) async {
    final index =
        _mockDrivers.indexWhere((d) => d.driverId == position.driverId);
    if (index >= 0) {
      _mockDrivers[index] = position;
    } else {
      _mockDrivers.add(position);
    }
    _pushUpdates();
    _logger.i('📍 Updated position for driver: ${position.driverId}');
  }

  /// Remove a driver from tracking.
  Future<void> removeDriver(String driverId) async {
    _mockDrivers.removeWhere((d) => d.driverId == driverId);
    _pushUpdates();
    _logger.i('🗑️ Removed driver from tracking: $driverId');
  }

  /// Stream of a single driver's position.
  Stream<DriverPositionModel?> getDriverPositionStream(String driverId) {
    return _allController.stream.map(
      (drivers) => drivers.cast<DriverPositionModel?>().firstWhere(
            (d) => d?.driverId == driverId,
            orElse: () => null,
          ),
    );
  }

  /// Get nearest available drivers to a location.
  Future<List<DriverPositionModel>> getNearestDrivers({
    required double lat,
    required double lng,
    int limit = 5,
    double maxDistanceKm = 50.0,
  }) async {
    final drivers = List<DriverPositionModel>.from(_availableDrivers);

    drivers.sort((a, b) =>
        _calculateDistance(a.lat, a.lng, lat, lng)
            .compareTo(_calculateDistance(b.lat, b.lng, lat, lng)));

    return drivers
        .where((d) =>
            _calculateDistance(d.lat, d.lng, lat, lng) <= maxDistanceKm)
        .take(limit)
        .toList();
  }

  /// Haversine formula — distance in kilometres between two coordinates.
  double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degree) => degree * (pi / 180);

  void dispose() {
    _allController.close();
    _availableController.close();
  }
}
