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
          .select('*, active_vehicle:vehicles(*)')
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
          .select('*, active_vehicle:vehicles(*)')
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
          .select('*, active_vehicle:vehicles(*)')
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

      final dataList = await _supabase.from(tableName).select('*, active_vehicle:vehicles(*)');

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

      final locationStr = 'POINT($lng $lat)';
      final updateData = <String, dynamic>{
        'current_location': locationStr,
        'last_location_update': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      final data = await _supabase
          .from(tableName)
          .update(updateData)
          .eq('id', driverId)
          .select('*, active_vehicle:vehicles(*)')
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
          .select('*, active_vehicle:vehicles(*)')
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
  Future<List<DriverPositionModel>> getNearestAvailableDrivers({
    required double lat,
    required double lng,
    required int limit,
    required double maxDistanceKm,
  }) async {
    try {
      _logger.i(
        '🔍 Fetching nearest available drivers via find_nearest_drivers RPC',
      );

      final response = await _supabase.rpc(
        'find_nearest_drivers',
        params: {
          'p_lat': lat,
          'p_lng': lng,
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
    } catch (e) {
      _logger.e('❌ Exception fetching nearest drivers: $e');
      rethrow;
    }
  }
}

