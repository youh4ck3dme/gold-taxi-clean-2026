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
    double parsedLat = (data['current_lat'] ?? data['lat'] ?? 0.0).toDouble();
    double parsedLng = (data['current_lng'] ?? data['lng'] ?? 0.0).toDouble();

    final locationData = data['current_location'];
    if (locationData != null) {
      if (locationData is String) {
        final match = RegExp(
          r'POINT\(([-0-9.]+) ([-0-9.]+)\)',
        ).firstMatch(locationData);
        if (match != null) {
          parsedLng = double.parse(match.group(1)!);
          parsedLat = double.parse(match.group(2)!);
        }
      } else if (locationData is Map && locationData['coordinates'] is List) {
        final coords = locationData['coordinates'] as List;
        parsedLng = coords[0].toDouble();
        parsedLat = coords[1].toDouble();
      }
    }

    // Handle nested vehicle data if present
    final vehicle = data['active_vehicle'] ?? {};
    final carModel =
        (vehicle['make'] != null
                ? "${vehicle['make']} ${vehicle['model']}"
                : (data['vehicle_type'] ?? data['carModel'] ?? 'Unknown'))
            as String;
    final carPlate =
        (vehicle['plate_number'] ??
                data['vehicle_plate'] ??
                data['carPlate'] ??
                'XXX-XXX')
            as String;

    return DriverPositionModel(
      driverId: id,
      name:
          (data['display_name'] ?? data['name'] ?? 'Unknown Driver') as String,
      avatar: (data['avatar'] ?? 'https://i.pravatar.cc/150?u=$id') as String,
      lat: parsedLat,
      lng: parsedLng,
      bearing: (data['bearing'] ?? data['heading'] ?? 0.0).toDouble(),
      isAvailable: (data['is_online'] ?? data['isAvailable'] ?? true) as bool,
      carModel: carModel,
      carPlate: carPlate,
      serviceType: (data['serviceType'] ?? 'Standard') as String,
      rating: (data['rating'] ?? 0.0).toDouble(),
      phone: (data['phone'] ?? '') as String,
      lastUpdated:
          DateTime.tryParse(
            (data['updated_at'] ?? data['lastUpdated'] ?? '').toString(),
          ) ??
          DateTime.now(),
    );
  }

  /// Convert to plain Map (Supabase upsert or JSON)
  Map<String, dynamic> toMap() {
    return {
      'display_name': name,
      'current_location': 'POINT($lng $lat)',
      'is_online': isAvailable,
      'phone': phone,
      'updated_at': lastUpdated.toIso8601String(),
      'current_lat': lat,
      'current_lng': lng,
      'bearing': bearing,
      'vehicle_type': carModel,
      'vehicle_plate': carPlate,
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
