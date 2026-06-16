import 'dart:async';
import 'ride_repository.dart';
import '../../../../models/ride_model.dart';
import '../../../../models/ride_status.dart';

class MockRideRepository implements RideRepository {
  final _ridesController = StreamController<List<RideModel>>.broadcast();
  final List<RideModel> _mockRides = [];

  MockRideRepository() {
    _ridesController.add(_mockRides);
  }

  @override
  Stream<List<RideModel>> getCustomerRides(String customerId) async* {
    yield _mockRides.where((r) => r.customerId == customerId).toList();
    await for (final rides in _ridesController.stream) {
      yield rides.where((r) => r.customerId == customerId).toList();
    }
  }

  @override
  Stream<RideModel?> getRide(String rideId) async* {
    yield _mockRides.where((r) => r.id == rideId).firstOrNull;
    await for (final rides in _ridesController.stream) {
      yield rides.where((r) => r.id == rideId).firstOrNull;
    }
  }

  @override
  Future<RideModel> createRide(RideModel ride) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _mockRides.add(ride);
    _ridesController.add(List.from(_mockRides));
    return ride;
  }

  @override
  Future<void> updateRideStatus(String rideId, RideStatus status, {String? cancellationReason}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockRides.indexWhere((r) => r.id == rideId);
    if (index != -1) {
      final oldRide = _mockRides[index];
      _mockRides[index] = oldRide.copyWith(
        status: status,
        updatedAt: DateTime.now(),
        cancelledAt: status == RideStatus.cancelled ? DateTime.now() : null,
        cancellationReason: cancellationReason,
        completedAt: status == RideStatus.completed ? DateTime.now() : null,
        startedAt: status == RideStatus.inProgress ? DateTime.now() : null,
      );
      _ridesController.add(List.from(_mockRides));
    }
  }

  @override
  Stream<List<RideModel>> getActiveRequests() async* {
    yield _mockRides.where((r) => r.status == RideStatus.requested).toList();
    await for (final rides in _ridesController.stream) {
      yield rides.where((r) => r.status == RideStatus.requested).toList();
    }
  }

  @override
  Future<RideModel> acceptRide(String rideId, String driverId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockRides.indexWhere((r) => r.id == rideId);
    if (index != -1) {
      final oldRide = _mockRides[index];
      if (oldRide.driverId != null) {
        throw Exception('Ride is no longer available');
      }
      final updatedRide = oldRide.copyWith(
        status: RideStatus.accepted,
        driverId: driverId,
        acceptedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _mockRides[index] = updatedRide;
      _ridesController.add(List.from(_mockRides));
      return updatedRide;
    }
    throw Exception('Ride not found');
  }

  @override
  Stream<RideModel?> getDriverActiveRide(String driverId) async* {
    yield _mockRides.where((r) =>
        r.driverId == driverId &&
        (r.status == RideStatus.accepted ||
         r.status == RideStatus.driverArriving ||
         r.status == RideStatus.inProgress)
    ).firstOrNull;
    await for (final rides in _ridesController.stream) {
      yield rides.where((r) =>
          r.driverId == driverId &&
          (r.status == RideStatus.accepted ||
           r.status == RideStatus.driverArriving ||
           r.status == RideStatus.inProgress)
      ).firstOrNull;
    }
  }

  @override
  Future<void> updateDriverStatus(String driverId, bool isOnline) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Stream<List<RideModel>> getAllRides() async* {
    yield List.from(_mockRides);
    await for (final rides in _ridesController.stream) {
      yield rides;
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> watchDriverLocation(String rideId) {
    return Stream.value([]);
  }

  @override
  Future<void> updateDriverLocation(String driverId, double lat, double lng, {double? heading}) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  void dispose() {
    _ridesController.close();
  }

  @override
  Future<bool> checkLocationInZone(double lat, double lng) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Košice area boundary mock
    if (lat >= 48.65 && lat <= 48.80 && lng >= 21.15 && lng <= 21.35) {
      return true;
    }
    return false;
  }

  @override
  Future<double> getSurgeMultiplier(double lat, double lng) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Returns 1.5 surge in city center for testing visual indicators
    if (lat >= 48.71 && lat <= 48.73 && lng >= 21.24 && lng <= 21.27) {
      return 1.5;
    }
    return 1.0;
  }
}
