import 'dart:typed_data';
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

  @override
  Future<void> registerAsDriver({
    required String vehicleType,
    required String vehiclePlate,
    required List<String> serviceClasses,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Používateľ nie je prihlásený.');
    }

    // Update profile role to driver
    await _client.from('profiles').update({'role': 'driver'}).eq('id', user.id);

    // Insert driver record
    await _client.from('drivers').insert({
      'user_id': user.id,
      'display_name': user.email?.split('@').first ?? 'Vodič',
      'vehicle_type': vehicleType,
      'vehicle_plate': vehiclePlate,
      'service_classes': serviceClasses,
      'is_online': false,
      'verification_status': 'pending_verification',
    });
  }

  @override
  Future<String> uploadDocument({
    required String documentType,
    required List<int> bytes,
    required String fileName,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Používateľ nie je prihlásený.');
    }

    // Format check
    final ext = fileName.split('.').last.toLowerCase();
    if (ext != 'jpg' && ext != 'jpeg' && ext != 'png') {
      throw Exception('Nepodporovaný formát súboru. Nahrajte iba JPG, JPEG alebo PNG.');
    }

    // Size check (max 5 MB)
    if (bytes.length > 5 * 1024 * 1024) {
      throw Exception('Súbor je príliš veľký. Maximálna veľkosť je 5 MB.');
    }

    final path = '${user.id}/${documentType}_${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage.from('driver-documents').uploadBinary(path, Uint8List.fromList(bytes));

    final publicUrl = _client.storage.from('driver-documents').getPublicUrl(path);
    return publicUrl;
  }

  @override
  Future<void> saveDriverDocuments({
    required String profilePhotoUrl,
    required String idCardUrl,
    required String licenseUrl,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Používateľ nie je prihlásený.');
    }

    final driver = await getDriverRecord(user.id);
    if (driver == null) {
      throw Exception('Záznam vodiča neexistuje.');
    }

    final driverId = driver['id'] as String;

    await _client.from('driver_documents').upsert({
      'driver_id': driverId,
      'profile_photo_url': profilePhotoUrl,
      'id_card_url': idCardUrl,
      'license_url': licenseUrl,
      'uploaded_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<Map<String, dynamic>?> getDriverDocuments(String driverId) async {
    return await _client
        .from('driver_documents')
        .select()
        .eq('driver_id', driverId)
        .maybeSingle();
  }

  @override
  Future<void> sendPhoneOtp(String phone) async {
    await _client.auth.signInWithOtp(
      phone: phone,
    );
  }

  @override
  Future<bool> verifyPhoneOtp(String phone, String code) async {
    try {
      final response = await _client.auth.verifyOTP(
        type: OtpType.sms,
        phone: phone,
        token: code,
      );
      return response.session != null || response.user != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> applyReferralCode(String code) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('Používateľ nie je prihlásený.');
    }

    final cleanCode = code.trim().toUpperCase();

    // Check if the code matches current user's own referral code
    final currentProfile = await _client
        .from('profiles')
        .select('referral_code, referred_by')
        .eq('id', currentUser.id)
        .single();

    if (currentProfile['referral_code']?.toString().toUpperCase() == cleanCode) {
      throw Exception('Nemôžete použiť vlastný referenčný kód.');
    }

    if (currentProfile['referred_by'] != null) {
      throw Exception('Už ste zadali referenčný kód.');
    }

    // Find the referrer profile
    final referrerData = await _client
        .from('profiles')
        .select('id')
        .eq('referral_code', cleanCode)
        .maybeSingle();

    if (referrerData == null) {
      throw Exception('Neplatný referenčný kód.');
    }

    final referrerId = referrerData['id'] as String;

    // Update current user's referred_by field
    await _client
        .from('profiles')
        .update({'referred_by': referrerId})
        .eq('id', currentUser.id);
  }
}
