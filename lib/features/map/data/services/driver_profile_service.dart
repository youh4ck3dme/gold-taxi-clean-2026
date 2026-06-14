import 'dart:math';

import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../models/driver_position_model.dart';

/// Service for managing driver profiles in Supabase
/// Handles CRUD operations for driver data
class DriverProfileService {
  final Logger _logger;
  final SupabaseClient _supabase;

  // Table name in Supabase
  static const String tableName = 'drivers';

  DriverProfileService({SupabaseClient? supabaseClient, Logger? logger})
    : _supabase = supabaseClient ?? Supabase.instance.client,
      _logger = logger ?? Logger();

  /// Create or update a driver profile in the database
  /// Returns the created/updated DriverPositionModel
  Future<DriverPositionModel> createOrUpdateDriverProfile(
    DriverPositionModel driver,
  ) async {
    try {
      _logger.i('📝 Saving driver profile: ${driver.driverId}');

      // Convert driver model to map for Supabase
      final driverData = driver.toMap();

      // Upsert (insert or update) the driver profile
      final data = await _supabase
          .from(tableName)
          .upsert(driverData)
          .select()
          .single();

      // Convert the response data back to DriverPositionModel
      final savedDriver = DriverPositionModel.fromMap(driver.driverId, data);

      _logger.i('✅ Driver profile saved successfully: ${savedDriver.driverId}');
      return savedDriver;
    } catch (e) {
      _logger.e('❌ Exception saving driver profile: $e');
      rethrow;
    }
  }

  /// Create a new driver profile
  /// Throws exception if driver with same ID already exists
  Future<DriverPositionModel> createDriverProfile(
    DriverPositionModel driver,
  ) async {
    try {
      _logger.i('🆕 Creating new driver profile: ${driver.driverId}');

      final driverData = driver.toMap();

      final data = await _supabase
          .from(tableName)
          .insert(driverData)
          .select()
          .single();

      final createdDriver = DriverPositionModel.fromMap(driver.driverId, data);

      _logger.i(
        '✅ Driver profile created successfully: ${createdDriver.driverId}',
      );
      return createdDriver;
    } catch (e) {
      _logger.e('❌ Exception creating driver profile: $e');
      rethrow;
    }
  }

  /// Get a driver profile by ID
  Future<DriverPositionModel?> getDriverProfile(String driverId) async {
    try {
      _logger.i('🔍 Fetching driver profile: $driverId');

      final data = await _supabase
          .from(tableName)
          .select()
          .eq('id', driverId)
          .maybeSingle();

      if (data == null) {
        _logger.w('⚠️ Driver profile not found: $driverId');
        return null;
      }

      final driver = DriverPositionModel.fromMap(driverId, data);

      _logger.i('✅ Driver profile fetched: ${driver.driverId}');
      return driver;
    } catch (e) {
      _logger.e('❌ Exception fetching driver profile: $e');
      rethrow;
    }
  }

  /// Get all driver profiles
  Future<List<DriverPositionModel>> getAllDriverProfiles() async {
    try {
      _logger.i('📋 Fetching all driver profiles');

      final dataList = await _supabase.from(tableName).select();

      final drivers = <DriverPositionModel>[];

      for (final data in dataList) {
        final driverId = data['id'] as String? ?? '';
        if (driverId.isNotEmpty) {
          drivers.add(DriverPositionModel.fromMap(driverId, data));
        }
      }

      _logger.i('✅ Fetched ${drivers.length} driver profiles');
      return drivers;
    } catch (e) {
      _logger.e('❌ Exception fetching driver profiles: $e');
      rethrow;
    }
  }

  /// Delete a driver profile
  Future<bool> deleteDriverProfile(String driverId) async {
    try {
      _logger.i('🗑️ Deleting driver profile: $driverId');

      await _supabase.from(tableName).delete().eq('id', driverId);

      _logger.i('✅ Driver profile deleted: $driverId');
      return true;
    } catch (e) {
      _logger.e('❌ Exception deleting driver profile: $e');
      rethrow;
    }
  }

  /// Update driver position (latitude and longitude)
  Future<DriverPositionModel> updateDriverPosition({
    required String driverId,
    required double lat,
    required double lng,
    double? bearing,
  }) async {
    try {
      _logger.i('📍 Updating position for driver: $driverId');

      final updateData = <String, dynamic>{
        'current_lat': lat,
        'current_lng': lng,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (bearing != null) {
        updateData['bearing'] = bearing;
      }

      final data = await _supabase
          .from(tableName)
          .update(updateData)
          .eq('id', driverId)
          .select()
          .single();

      final updatedDriver = DriverPositionModel.fromMap(driverId, data);

      _logger.i('✅ Position updated for driver: $driverId');
      return updatedDriver;
    } catch (e) {
      _logger.e('❌ Exception updating position: $e');
      rethrow;
    }
  }

  /// Update driver availability status
  Future<DriverPositionModel> updateDriverAvailability({
    required String driverId,
    required bool isOnline,
  }) async {
    try {
      _logger.i('🔄 Updating availability for driver: $driverId');

      final data = await _supabase
          .from(tableName)
          .update({
            'is_online': isOnline,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', driverId)
          .select()
          .single();

      final updatedDriver = DriverPositionModel.fromMap(driverId, data);

      _logger.i('✅ Availability updated for driver: $driverId');
      return updatedDriver;
    } catch (e) {
      _logger.e('❌ Exception updating availability: $e');
      rethrow;
    }
  }

  /// Get nearest available drivers
  /// Uses a Supabase RPC function 'get_nearest_drivers' or falls back to client-side filtering if RPC is not available.
  Future<List<DriverPositionModel>> getNearestAvailableDrivers({
    required double lat,
    required double lng,
    required int limit,
    required double maxDistanceKm,
  }) async {
    try {
      _logger.i(
        '🔍 Fetching nearest available drivers within ${maxDistanceKm}km',
      );

      try {
        // Try to use PostGIS RPC function if it exists in Supabase
        final response = await _supabase.rpc(
          'get_nearest_drivers',
          params: {
            'p_lat': lat,
            'p_lng': lng,
            'p_max_distance_km': maxDistanceKm,
            'p_limit': limit,
          },
        );

        final drivers = <DriverPositionModel>[];
        for (final data in (response as List<dynamic>)) {
          final mapData = Map<String, dynamic>.from(data as Map);
          final driverId = mapData['id'] as String? ?? '';
          if (driverId.isNotEmpty) {
            drivers.add(DriverPositionModel.fromMap(driverId, mapData));
          }
        }
        _logger.i('✅ Fetched ${drivers.length} nearest drivers via RPC');
        return drivers;
      } catch (rpcError) {
        // Fallback: Fetch all available drivers and sort client-side (Not ideal for large datasets)
        _logger.w(
          '⚠️ RPC get_nearest_drivers failed or not found, falling back to client-side filtering. Error: $rpcError',
        );

        final dataList = await _supabase
            .from(tableName)
            .select()
            .eq('is_online', true);

        final drivers = <DriverPositionModel>[];
        for (final data in dataList) {
          final driverId = data['id'] as String? ?? '';
          if (driverId.isNotEmpty) {
            drivers.add(DriverPositionModel.fromMap(driverId, data));
          }
        }

        final nearbyDrivers =
            drivers
                .where(
                  (driver) =>
                      _distanceKm(driver.lat, driver.lng, lat, lng) <=
                      maxDistanceKm,
                )
                .toList()
              ..sort(
                (a, b) => _distanceKm(
                  a.lat,
                  a.lng,
                  lat,
                  lng,
                ).compareTo(_distanceKm(b.lat, b.lng, lat, lng)),
              );

        final limitedDrivers = nearbyDrivers.take(limit).toList();
        _logger.i(
          '✅ Fetched ${limitedDrivers.length} nearest drivers via fallback',
        );
        return limitedDrivers;
      }
    } catch (e) {
      _logger.e('❌ Exception fetching nearest drivers: $e');
      rethrow;
    }
  }

  double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degree) => degree * (pi / 180);
}
