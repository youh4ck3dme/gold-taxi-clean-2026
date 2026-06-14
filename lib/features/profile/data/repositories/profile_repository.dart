import '../../../../models/user_model.dart';

abstract class ProfileRepository {
  /// Fetch user profile details
  Future<UserModel> getUserProfile();

  /// Update customer profile details (whitelisted fields only)
  Future<UserModel> updateCustomerProfile({
    required String fullName,
    required String phone,
    required Map<String, dynamic> savedAddresses,
  });

  /// Update driver profile details (whitelisted fields only)
  Future<void> updateDriverProfile({
    required String vehicleType,
    required String vehiclePlate,
    required List<String> serviceClasses,
    required bool isOnline,
  });

  /// Fetch driver record details for driver profile page
  Future<Map<String, dynamic>?> getDriverRecord(String userId);

  /// Fetch aggregated driver statistics (total rides, earnings, avg rating)
  Future<Map<String, dynamic>> getDriverStats(String driverId);

  /// Fetch order history for the current user
  Future<List<Map<String, dynamic>>> getOrderHistory(String userId);

  /// Fetch booking history for the current user
  Future<List<dynamic>> getBookingHistory(String userId);
}
