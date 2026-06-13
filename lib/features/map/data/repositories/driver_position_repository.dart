import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../../../../models/driver_position_model.dart';

/// Repository for managing driver positions in Firestore
class DriverPositionRepository {
  final FirebaseFirestore _firestore;
  final Logger _logger = Logger();

  static const String _collectionName = 'driver_positions';

  DriverPositionRepository(this._firestore);

  /// Get stream of all driver positions (realtime updates)
  Stream<List<DriverPositionModel>> getDriverPositionsStream() {
    _logger.i('📡 Listening to driver positions...');
    return _firestore
        .collection(_collectionName)
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DriverPositionModel.fromFirestore(doc))
            .toList())
        .handleError((error) {
      _logger.e('Error streaming driver positions: $error');
      return <DriverPositionModel>[];
    });
  }

  /// Get stream of available drivers only
  Stream<List<DriverPositionModel>> getAvailableDriversStream() {
    return _firestore
        .collection(_collectionName)
        .where('isAvailable', isEqualTo: true)
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DriverPositionModel.fromFirestore(doc))
            .toList())
        .handleError((error) {
      _logger.e('Error streaming available drivers: $error');
      return <DriverPositionModel>[];
    });
  }

  /// Update driver position
  Future<void> updateDriverPosition(DriverPositionModel position) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(position.driverId)
          .set(position.toFirestore(), SetOptions(merge: true));
      _logger.i('📍 Updated position for driver: ${position.driverId}');
    } catch (e) {
      _logger.e('Error updating driver position: $e');
      rethrow;
    }
  }

  /// Remove driver from tracking
  Future<void> removeDriver(String driverId) async {
    try {
      await _firestore.collection(_collectionName).doc(driverId).delete();
      _logger.i('🗑️ Removed driver from tracking: $driverId');
    } catch (e) {
      _logger.e('Error removing driver: $e');
      rethrow;
    }
  }

  /// Get single driver position
  Stream<DriverPositionModel?> getDriverPositionStream(String driverId) {
    return _firestore
        .collection(_collectionName)
        .doc(driverId)
        .snapshots()
        .map((doc) => doc.exists
            ? DriverPositionModel.fromFirestore(doc)
            : null)
        .handleError((error) {
      _logger.e('Error streaming driver position: $error');
      return null;
    });
  }

  /// Get nearest available drivers to a location
  Future<List<DriverPositionModel>> getNearestDrivers({
    required double lat,
    required double lng,
    int limit = 5,
    double maxDistanceKm = 50.0,
  }) async {
    try {
      // Get all available drivers
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('isAvailable', isEqualTo: true)
          .get();

      final drivers = snapshot.docs
          .map((doc) => DriverPositionModel.fromFirestore(doc))
          .toList();

      // Sort by distance (Haversine formula)
      drivers.sort((a, b) => _calculateDistance(a.lat, a.lng, lat, lng)
          .compareTo(_calculateDistance(b.lat, b.lng, lat, lng)));

      // Filter by max distance and limit
      return drivers
          .where((driver) => _calculateDistance(driver.lat, driver.lng, lat, lng) <= maxDistanceKm)
          .take(limit)
          .toList();
    } catch (e) {
      _logger.e('Error getting nearest drivers: $e');
      return [];
    }
  }

  /// Calculate distance between two points in kilometers (Haversine formula)
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371; // Earth radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degree) {
    return degree * (3.141592653589793 / 180);
  }

  /// Add mock drivers for demo purposes
  Future<void> addMockDrivers() async {
    final mockDrivers = [
      DriverPositionModel(
        driverId: 'driver_1',
        name: 'Ján Novák',
        avatar: 'https://i.pravatar.cc/150?u=1',
        lat: 48.1486,
        lng: 17.1077,
        bearing: 45.0,
        isAvailable: true,
        carModel: 'Škoda Octavia',
        carPlate: 'BA-123-AB',
        serviceType: 'Standard',
        rating: 4.8,
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

    for (final driver in mockDrivers) {
      await updateDriverPosition(driver);
    }
    _logger.i('✅ Added ${mockDrivers.length} mock drivers to Firestore');
  }
}
