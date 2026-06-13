import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Create from Firestore document
  factory DriverPositionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DriverPositionModel(
      driverId: doc.id,
      name: data['name'] as String? ?? 'Unknown Driver',
      avatar: data['avatar'] as String? ?? 'https://i.pravatar.cc/150?u=\${doc.id}',
      lat: (data['lat'] as num? ?? 0.0).toDouble(),
      lng: (data['lng'] as num? ?? 0.0).toDouble(),
      bearing: (data['bearing'] as num? ?? 0.0).toDouble(),
      isAvailable: data['isAvailable'] as bool? ?? true,
      carModel: data['carModel'] as String? ?? 'Unknown',
      carPlate: data['carPlate'] as String? ?? 'XXX-XXX',
      serviceType: data['serviceType'] as String? ?? 'Standard',
      rating: (data['rating'] as num? ?? 0.0).toDouble(),
      phone: data['phone'] as String? ?? '',
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'avatar': avatar,
      'lat': lat,
      'lng': lng,
      'bearing': bearing,
      'isAvailable': isAvailable,
      'carModel': carModel,
      'carPlate': carPlate,
      'serviceType': serviceType,
      'rating': rating,
      'phone': phone,
      'lastUpdated': Timestamp.now(),
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
