import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ride_repository.dart';
import '../../../../models/ride_model.dart';
import '../../../../models/ride_status.dart';

class SupabaseRideRepository implements RideRepository {
  final SupabaseClient _client;

  SupabaseRideRepository(this._client);

  @override
  Stream<List<RideModel>> getCustomerRides(String customerId) {
    return _client
        .from('rides')
        .stream(primaryKey: ['id'])
        .eq('customer_id', customerId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => RideModel.fromJson(json)).toList());
  }

  @override
  Stream<RideModel?> getRide(String rideId) {
    return _client
        .from('rides')
        .stream(primaryKey: ['id'])
        .eq('id', rideId)
        .limit(1)
        .map((data) => data.isEmpty ? null : RideModel.fromJson(data.first));
  }

  @override
  Future<RideModel> createRide(RideModel ride) async {
    final response = await _client.from('rides').insert(ride.toDbJson()).select().single();
    return RideModel.fromJson(response);
  }

  @override
  Future<void> updateRideStatus(
    String rideId,
    RideStatus status, {
    String? cancellationReason,
  }) async {
    if (status == RideStatus.cancelled) {
      await _client.rpc(
        'cancel_ride',
        params: {'p_ride_id': rideId, 'p_reason': cancellationReason},
      );
    } else {
      await _client.rpc('update_ride_status', params: {
        'p_ride_id': rideId,
        'p_new_status': status.dbValue,
      });
    }
  }

  @override
  Stream<List<RideModel>> getActiveRequests() {
    return _client
        .from('rides')
        .stream(primaryKey: ['id'])
        .eq('status', 'requested')
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => RideModel.fromJson(json)).toList());
  }

  @override
  Future<RideModel> acceptRide(String rideId, String driverId) async {
    final response = await _client.rpc('accept_ride', params: {
      'p_ride_id': rideId,
    }).select().single();
    return RideModel.fromJson(response);
  }

  @override
  Stream<RideModel?> getDriverActiveRide(String driverId) {
    return _client
        .from('rides')
        .stream(primaryKey: ['id'])
        .eq('driver_id', driverId)
        .map((data) {
          final activeRides = data
              .map((json) => RideModel.fromJson(json))
              .where((ride) =>
                  ride.status == RideStatus.accepted ||
                  ride.status == RideStatus.driverArriving ||
                  ride.status == RideStatus.inProgress)
              .toList();
          return activeRides.isEmpty ? null : activeRides.first;
        });
  }

  @override
  Future<void> updateDriverStatus(String driverId, bool isOnline) async {
    final normalizedDriverId = driverId.trim();
    if (normalizedDriverId.isEmpty) {
      throw StateError('Cannot update driver status without a driver id.');
    }

    await _client
        .from('drivers')
        .update({'is_online': isOnline})
        .eq('user_id', normalizedDriverId);
  }

  @override
  Stream<List<RideModel>> getAllRides() {
    return _client
        .from('rides')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => RideModel.fromJson(json)).toList());
  }

  @override
  Stream<List<Map<String, dynamic>>> watchDriverLocation(String rideId) {
    return _client
        .from('driver_locations')
        .stream(primaryKey: ['id'])
        .eq('ride_id', rideId)
        .order('created_at', ascending: false)
        .limit(1);
  }

  @override
  Future<void> updateDriverLocation(
    String driverId,
    double lat,
    double lng, {
    double? heading,
  }) async {
    final locationStr = 'POINT($lng $lat)';

    await _client.from('driver_locations').insert({
      'driver_id': driverId,
      'location': locationStr,
      'heading': heading,
    });

    await _client
        .from('drivers')
        .update({
          'current_location': locationStr,
          'last_location_update': DateTime.now().toIso8601String(),
        })
        .eq('id', driverId);
  }

  @override
  Future<bool> checkLocationInZone(double lat, double lng) async {
    try {
      final response = await _client.rpc('check_location_in_zone', params: {
        'p_lat': lat,
        'p_lng': lng,
      });
      return response as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<double> getSurgeMultiplier(double lat, double lng) async {
    try {
      final response = await _client.rpc('calculate_surge_pricing', params: {
        'p_lat': lat,
        'p_lng': lng,
      });
      if (response is num) {
        return response.toDouble();
      }
      return double.tryParse(response.toString()) ?? 1.0;
    } catch (_) {
      return 1.0;
    }
  }
}
