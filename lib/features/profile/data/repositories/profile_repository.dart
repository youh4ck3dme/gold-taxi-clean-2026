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

  /// Register current user as a driver
  Future<void> registerAsDriver({
    required String vehicleType,
    required String vehiclePlate,
    required List<String> serviceClasses,
  });

  /// Upload driver document to Supabase Storage (returns public URL)
  Future<String> uploadDocument({
    required String documentType,
    required List<int> bytes,
    required String fileName,
  });

  /// Save driver document URLs into the database
  Future<void> saveDriverDocuments({
    required String profilePhotoUrl,
    required String idCardUrl,
    required String licenseUrl,
  });

  /// Get driver documents URLs
  Future<Map<String, dynamic>?> getDriverDocuments(String driverId);

  /// Send SMS OTP verification code to a phone number
  Future<void> sendPhoneOtp(String phone);

  /// Verify SMS OTP verification code for a phone number
  Future<bool> verifyPhoneOtp(String phone, String code);

  /// Apply a referral code of another user to set referred_by
  Future<void> applyReferralCode(String code);
}
