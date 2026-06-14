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
  Stream<List<RideModel>> getCustomerRides(String customerId) {
    return _ridesController.stream.map(
      (rides) => rides.where((r) => r.customerId == customerId).toList(),
    );
  }

  @override
  Stream<RideModel?> getRide(String rideId) {
    return _ridesController.stream.map(
      (rides) => rides.where((r) => r.id == rideId).firstOrNull,
    );
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
  Stream<List<RideModel>> getActiveRequests() {
    return _ridesController.stream.map(
      (rides) => rides.where((r) => r.status == RideStatus.requested).toList(),
    );
  }

  @override
  Future<void> acceptRide(String rideId, String driverId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockRides.indexWhere((r) => r.id == rideId);
    if (index != -1) {
      final oldRide = _mockRides[index];
      _mockRides[index] = oldRide.copyWith(
        status: RideStatus.accepted,
        driverId: driverId,
        acceptedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _ridesController.add(List.from(_mockRides));
    }
  }

  @override
  Future<void> updateDriverStatus(String driverId, bool isOnline) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Stream<List<RideModel>> getAllRides() {
    return _ridesController.stream;
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
}
