import 'package:equatable/equatable.dart';

/// Model for real-time driver position tracking
class DriverPositionModel extends Equatable {
  final String driverId;
  final String name;
  final String avatar;
  final double lat;
  final double lng;
  final double bearing;
  final bool isAvailable;
  final String carModel;
  final String carPlate;
  final String serviceType;
  final double rating;
  final String phone;
  final DateTime lastUpdated;

  const DriverPositionModel({
    required this.driverId,
    required this.name,
    required this.avatar,
    required this.lat,
    required this.lng,
    this.bearing = 0.0,
    this.isAvailable = true,
    this.carModel = 'Unknown',
    this.carPlate = 'XXX-XXX',
    this.serviceType = 'Standard',
    this.rating = 0.0,
    this.phone = '',
    required this.lastUpdated,
  });

  /// Create from a plain Map (Supabase row or JSON)
  factory DriverPositionModel.fromMap(String id, Map<String, dynamic> data) {
    return DriverPositionModel(
      driverId: id,
      name: (data['display_name'] ?? data['name'] ?? 'Unknown Driver') as String,
      avatar: (data['avatar'] ?? 'https://i.pravatar.cc/150?u=$id') as String,
      lat: (data['current_lat'] ?? data['lat'] ?? 0.0).toDouble(),
      lng: (data['current_lng'] ?? data['lng'] ?? 0.0).toDouble(),
      bearing: (data['bearing'] ?? 0.0).toDouble(),
      isAvailable: (data['is_online'] ?? data['isAvailable'] ?? true) as bool,
      carModel: (data['vehicle_type'] ?? data['carModel'] ?? 'Unknown') as String,
      carPlate: (data['vehicle_plate'] ?? data['carPlate'] ?? 'XXX-XXX') as String,
      serviceType: (data['serviceType'] ?? 'Standard') as String,
      rating: (data['rating'] ?? 0.0).toDouble(),
      phone: (data['phone'] ?? '') as String,
      lastUpdated: DateTime.tryParse((data['updated_at'] ?? data['lastUpdated'] ?? '').toString()) ?? DateTime.now(),
    );
  }

  /// Convert to plain Map (Supabase upsert or JSON)
  Map<String, dynamic> toMap() {
    return {
      'display_name': name,
      'current_lat': lat,
      'current_lng': lng,
      'bearing': bearing,
      'is_online': isAvailable,
      'vehicle_type': carModel,
      'vehicle_plate': carPlate,
      'phone': phone,
      'updated_at': lastUpdated.toIso8601String(),
    };
  }

  /// Create a copy with new position
  DriverPositionModel copyWithNewPosition({
    required double lat,
    required double lng,
    double? bearing,
    bool? isAvailable,
  }) {
    return DriverPositionModel(
      driverId: driverId,
      name: name,
      avatar: avatar,
      lat: lat,
      lng: lng,
      bearing: bearing ?? this.bearing,
      isAvailable: isAvailable ?? this.isAvailable,
      carModel: carModel,
      carPlate: carPlate,
      serviceType: serviceType,
      rating: rating,
      phone: phone,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    driverId,
    name,
    avatar,
    lat,
    lng,
    bearing,
    isAvailable,
    carModel,
    carPlate,
    serviceType,
    rating,
    phone,
    lastUpdated,
  ];
}
