import 'package:supabase_flutter/supabase_flutter.dart';

/// Model pre uloženie polohy a stavu vodiča
class DriverLocation {
  final String id;
  final double latitude;
  final double longitude;
  final bool isOnline;
  final DateTime updatedAt;
  final String fullName;

  DriverLocation({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.isOnline,
    required this.updatedAt,
    required this.fullName,
  });

  factory DriverLocation.fromMap(Map<String, dynamic> map) {
    return DriverLocation(
      id: map['id'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      isOnline: map['is_online'] ?? false,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : DateTime.now(),
      fullName: map['full_name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'is_online': isOnline,
      'updated_at': updatedAt.toIso8601String(),
      'full_name': fullName,
    };
  }
}

/// Repository pre komunikáciu s tabuľkou `driver_locations` v Supabase
class DriverLocationRepository {
  final SupabaseClient _supabase;

  DriverLocationRepository({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  /// Aktualizácia polohy vodiča
  Future<void> updateLocation(String driverId, double latitude, double longitude) async {
    try {
      await _supabase.from('driver_locations').upsert({
        'id': driverId,
        'latitude': latitude,
        'longitude': longitude,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Chyba pri aktualizácii polohy: ${e.toString()}');
    }
  }

  /// Zapnutie/vypnutie online stavu vodiča
  Future<void> toggleOnlineStatus(String driverId, bool isOnline) async {
    try {
      await _supabase.from('driver_locations').upsert({
        'id': driverId,
        'is_online': isOnline,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Chyba pri zmene online stavu: ${e.toString()}');
    }
  }

  /// Streamovanie online vodičov v reálnom čase
  Stream<List<DriverLocation>> streamOnlineDrivers() {
    return _supabase
        .from('driver_locations')
        .stream(primaryKey: ['id'])
        .map((list) => list
            .map((map) => DriverLocation.fromMap(map))
            .where((driver) => driver.isOnline)
            .toList());
  }

  /// Získanie aktuálneho stavu konkrétneho vodiča
  Future<DriverLocation?> getDriverLocation(String driverId) async {
    try {
      final data = await _supabase
          .from('driver_locations')
          .select()
          .eq('id', driverId)
          .maybeSingle();
      if (data == null) return null;
      return DriverLocation.fromMap(data);
    } catch (e) {
      return null;
    }
  }
}
