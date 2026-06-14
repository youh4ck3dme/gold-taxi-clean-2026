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
  Future<List<Map<String, dynamic>>> getOrderHistory(String userId) async {
    // Return empty list or fetch from Supabase rides if needed.
    // In Supabase mode, order/ride history is loaded via RideRepository or maps.
    return [];
  }

  @override
  Future<List<dynamic>> getBookingHistory(String userId) async {
    return [];
  }
}
