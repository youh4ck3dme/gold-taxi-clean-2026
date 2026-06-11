import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:gold_taxi/core/constants/api_constants.dart';
import 'package:gold_taxi/core/services/api_service.dart';
import 'package:gold_taxi/models/user_model.dart';
import 'package:gold_taxi/models/booking_model.dart';

class ProfileRepository {
  final ApiService _apiService;
  final Connectivity _connectivity;

  ProfileRepository(this._apiService, this._connectivity);

  /// Fetch user profile details
  Future<UserModel> getUserProfile() async {
    final response = await _apiService.get('/wp-json/wp/v2/users/me');
    return UserModel.fromJson(response as Map<String, dynamic>);
  }

  /// Update user profile details
  Future<UserModel> updateUserProfile({
    required String name,
    required String bio,
  }) async {
    final response = await _apiService.post(
      '/wp-json/wp/v2/users/me',
      data: {
        'name': name,
        'description': bio,
      },
    );
    return UserModel.fromJson(response as Map<String, dynamic>);
  }

  /// Fetch order history for the current user from WooCommerce
  Future<List<Map<String, dynamic>>> getOrderHistory(int userId) async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) return [];

    try {
      final response = await _apiService.get(
        '/wp-json/wc/v3/orders',
        queryParameters: {'customer': userId},
      );
      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  /// Fetch booking history for the current user from JetEngine
  Future<List<BookingModel>> getBookingHistory(int userId) async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) return [];

    try {
      final response = await _apiService.get(
        ApiConstants.bookingsEndpoint,
        queryParameters: {'customer_id': userId},
      );
      if (response is List) {
        return response.map((item) => BookingModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }
}
