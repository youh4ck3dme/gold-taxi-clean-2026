import '../../../../models/ride_model.dart';
import '../../../../models/ride_status.dart';

abstract class RideRepository {
  /// Stream of rides for a specific customer
  Stream<List<RideModel>> getCustomerRides(String customerId);

  /// Stream of a specific ride by ID
  Stream<RideModel?> getRide(String rideId);

  /// Create a new ride request
  Future<RideModel> createRide(RideModel ride);

  /// Update ride status (enforcing transitions should be handled in implementation or Cubit)
  Future<void> updateRideStatus(String rideId, RideStatus status, {String? cancellationReason});

  /// [Driver] Get stream of all active ride requests
  Stream<List<RideModel>> getActiveRequests();

  /// [Driver] Accept a ride request
  Future<void> acceptRide(String rideId, String driverId);

  /// [Driver] Update driver online/offline status
  Future<void> updateDriverStatus(String driverId, bool isOnline);

  /// [Admin] Get stream of all rides for monitoring
  Stream<List<RideModel>> getAllRides();

  /// Watch driver location for a specific ride
  Stream<List<Map<String, dynamic>>> watchDriverLocation(String rideId);

  /// Update driver location
  Future<void> updateDriverLocation(String driverId, double lat, double lng, {double? heading});
}
