import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_repository.dart';
import '../../../../models/user_model.dart';

class SupabaseProfileRepository implements ProfileRepository {
  final SupabaseClient _client;

  SupabaseProfileRepository(this._client);

  @override
  Future<UserModel> getUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Používateľ nie je prihlásený.');
    }

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return UserModel.fromJson(data);
  }

  @override
  Future<UserModel> updateCustomerProfile({
    required String fullName,
    required String phone,
    required Map<String, dynamic> savedAddresses,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Používateľ nie je prihlásený.');
    }

    // Safely update ONLY whitelisted fields
    final updatePayload = {
      'full_name': fullName,
      'phone': phone,
      'saved_addresses': savedAddresses,
    };

    final data = await _client
        .from('profiles')
        .update(updatePayload)
        .eq('id', user.id)
        .select()
        .single();

    return UserModel.fromJson(data);
  }

  @override
  Future<void> updateDriverProfile({
    required String vehicleType,
    required String vehiclePlate,
    required List<String> serviceClasses,
    required bool isOnline,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Používateľ nie je prihlásený.');
    }

    // Safely update ONLY whitelisted fields in the drivers table
    final updatePayload = {
      'vehicle_type': vehicleType,
      'vehicle_plate': vehiclePlate,
      'service_classes': serviceClasses,
      'is_online': isOnline,
    };

    await _client
        .from('drivers')
        .update(updatePayload)
        .eq('user_id', user.id);
  }

  @override
  Future<Map<String, dynamic>?> getDriverRecord(String userId) async {
    final data = await _client
        .from('drivers')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    return data;
  }

  @override
  Future<Map<String, dynamic>> getDriverStats(String driverId) async {
    final data = await _client
        .from('rides')
        .select('status, final_price, estimated_price, rating')
        .eq('driver_id', driverId);

    final completedRides = (data as List)
        .where((r) => r['status'] == 'completed')
        .toList();

    final totalRides = completedRides.length;

    double totalEarnings = 0;
    double ratingSum = 0;
    int ratingCount = 0;

    for (final ride in completedRides) {
      final price = (ride['final_price'] ?? ride['estimated_price']);
      if (price != null) {
        totalEarnings += (price is num) ? price.toDouble() : double.tryParse(price.toString()) ?? 0;
      }
      final rating = ride['rating'];
      if (rating != null) {
        ratingSum += (rating is num) ? rating.toDouble() : double.tryParse(rating.toString()) ?? 0;
        ratingCount++;
      }
    }

    return {
      'totalRides': totalRides,
      'totalEarnings': totalEarnings,
      'averageRating': ratingCount > 0 ? (ratingSum / ratingCount) : null,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getOrderHistory(String userId) async {
    // In Supabase mode, order history comes from rides table via RideRepository
    return [];
  }

  @override
  Future<List<dynamic>> getBookingHistory(String userId) async {
    return [];
  }
}
