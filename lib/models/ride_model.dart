import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'ride_status.dart';
import 'ride_stop.dart';
import '../core/services/pricing_service.dart';

class RideModel extends Equatable {
  final String id;
  final String customerId;
  final String? driverId;
  final String pickupAddress;
  final LatLng pickupLatLng;
  final String dropoffAddress;
  final LatLng dropoffLatLng;
  final ServiceType serviceType;
  final double estimatedDistance;
  final double estimatedDuration;
  final double estimatedPrice;
  final double? finalPrice;
  final RideStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final String? passengerNote;
  final List<RideStop> stops;

  final String? vehicleId;
  final int? rating;
  final String? reviewText;

  const RideModel({
    required this.id,
    required this.customerId,
    this.driverId,
    this.vehicleId,
    required this.pickupAddress,
    required this.pickupLatLng,
    required this.dropoffAddress,
    required this.dropoffLatLng,
    required this.serviceType,
    required this.estimatedDistance,
    required this.estimatedDuration,
    required this.estimatedPrice,
    this.finalPrice,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.passengerNote,
    this.rating,
    this.reviewText,
    this.stops = const [],
  });

  RideModel copyWith({
    String? id,
    String? customerId,
    String? driverId,
    String? vehicleId,
    String? pickupAddress,
    LatLng? pickupLatLng,
    String? dropoffAddress,
    LatLng? dropoffLatLng,
    ServiceType? serviceType,
    double? estimatedDistance,
    double? estimatedDuration,
    double? estimatedPrice,
    double? finalPrice,
    RideStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? cancellationReason,
    String? passengerNote,
    int? rating,
    String? reviewText,
    List<RideStop>? stops,
  }) {
    return RideModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      driverId: driverId ?? this.driverId,
      vehicleId: vehicleId ?? this.vehicleId,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupLatLng: pickupLatLng ?? this.pickupLatLng,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      dropoffLatLng: dropoffLatLng ?? this.dropoffLatLng,
      serviceType: serviceType ?? this.serviceType,
      estimatedDistance: estimatedDistance ?? this.estimatedDistance,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      finalPrice: finalPrice ?? this.finalPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      passengerNote: passengerNote ?? this.passengerNote,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      stops: stops ?? this.stops,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'driver_id': driverId,
      'vehicle_id': vehicleId,
      'pickup_address': pickupAddress,
      'pickup_lat': pickupLatLng.latitude,
      'pickup_lng': pickupLatLng.longitude,
      'dropoff_address': dropoffAddress,
      'dropoff_lat': dropoffLatLng.latitude,
      'dropoff_lng': dropoffLatLng.longitude,
      'service_type': serviceType.name,
      'estimated_distance_km': estimatedDistance,
      'estimated_duration_min': estimatedDuration,
      'estimated_price': estimatedPrice,
      'final_price': finalPrice,
      'status': status.dbValue,
      'rating': rating,
      'review_text': reviewText,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'cancellation_reason': cancellationReason,
      'passenger_note': passengerNote,
      'stops': stops.map((s) => s.toJson()).toList(),
    };
  }

  Map<String, dynamic> toDbJson() {
    final json = toJson();
    json.remove('stops');
    json.remove('pickup_lat');
    json.remove('pickup_lng');
    json.remove('dropoff_lat');
    json.remove('dropoff_lng');

    // PostGIS POINT format: POINT(longitude latitude)
    json['pickup_location'] =
        'POINT(${pickupLatLng.longitude} ${pickupLatLng.latitude})';
    json['dropoff_location'] =
        'POINT(${dropoffLatLng.longitude} ${dropoffLatLng.latitude})';

    final driverIdVal = json['driver_id'] as String?;
    if (driverIdVal != null) {
      final isValidUuid = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      ).hasMatch(driverIdVal);
      if (!isValidUuid) {
        json['driver_id'] = null;
      }
    }
    return json;
  }

  factory RideModel.fromJson(Map<String, dynamic> json) {
    LatLng parsePoint(
      dynamic pointData,
      double fallbackLat,
      double fallbackLng,
    ) {
      if (pointData == null) return LatLng(fallbackLat, fallbackLng);
      // Supabase might return as string "POINT(lng lat)" or as GeoJSON map
      if (pointData is String) {
        final match = RegExp(
          r'POINT\(([-0-9.]+) ([-0-9.]+)\)',
        ).firstMatch(pointData);
        if (match != null) {
          final lng = double.parse(match.group(1)!);
          final lat = double.parse(match.group(2)!);
          return LatLng(lat, lng);
        }
      } else if (pointData is Map && pointData['coordinates'] is List) {
        final coords = pointData['coordinates'] as List;
        return LatLng(coords[1].toDouble(), coords[0].toDouble());
      }
      return LatLng(fallbackLat, fallbackLng);
    }

    return RideModel(
      id: json['id'] as String,
      customerId: (json['customer_id'] ?? json['customerId']) as String,
      driverId: (json['driver_id'] ?? json['driverId']) as String?,
      vehicleId: (json['vehicle_id'] ?? json['vehicleId']) as String?,
      pickupAddress:
          (json['pickup_address'] ?? json['pickupAddress']) as String,
      pickupLatLng: parsePoint(
        json['pickup_location'],
        (json['pickup_lat'] ?? 0.0).toDouble(),
        (json['pickup_lng'] ?? 0.0).toDouble(),
      ),
      dropoffAddress:
          (json['dropoff_address'] ?? json['dropoffAddress']) as String,
      dropoffLatLng: parsePoint(
        json['dropoff_location'],
        (json['dropoff_lat'] ?? 0.0).toDouble(),
        (json['dropoff_lng'] ?? 0.0).toDouble(),
      ),
      serviceType: ServiceType.values.byName(
        (json['service_type'] ?? json['serviceType'] ?? 'standard') as String,
      ),
      estimatedDistance:
          (json['estimated_distance_km'] ??
                  json['estimatedDistance'] as num? ??
                  0.0)
              .toDouble(),
      estimatedDuration:
          (json['estimated_duration_min'] ??
                  json['estimatedDuration'] as num? ??
                  0.0)
              .toDouble(),
      estimatedPrice:
          (json['estimated_price'] ?? json['estimatedPrice'] as num? ?? 0.0)
              .toDouble(),
      finalPrice: (json['final_price'] ?? json['finalPrice'] as num?)
          ?.toDouble(),
      status: RideStatusExtension.fromDbValue(
        json['status'] as String? ?? 'requested',
      ),
      rating: json['rating'] as int?,
      reviewText: json['review_text'] as String?,
      createdAt: DateTime.parse(
        (json['created_at'] ??
                json['createdAt'] ??
                DateTime.now().toIso8601String())
            as String,
      ),
      updatedAt: DateTime.parse(
        (json['updated_at'] ??
                json['updatedAt'] ??
                DateTime.now().toIso8601String())
            as String,
      ),
      acceptedAt: (json['accepted_at'] ?? json['acceptedAt']) != null
          ? DateTime.parse(
              (json['accepted_at'] ?? json['acceptedAt']) as String,
            )
          : null,
      startedAt: (json['started_at'] ?? json['startedAt']) != null
          ? DateTime.parse((json['started_at'] ?? json['startedAt']) as String)
          : null,
      completedAt: (json['completed_at'] ?? json['completedAt']) != null
          ? DateTime.parse(
              (json['completed_at'] ?? json['completedAt']) as String,
            )
          : null,
      cancelledAt: (json['cancelled_at'] ?? json['cancelledAt']) != null
          ? DateTime.parse(
              (json['cancelled_at'] ?? json['cancelledAt']) as String,
            )
          : null,
      cancellationReason:
          (json['cancellation_reason'] ?? json['cancellationReason'])
              as String?,
      passengerNote:
          (json['passenger_note'] ?? json['passengerNote']) as String?,
      stops:
          (json['stops'] as List<dynamic>?)
              ?.map((s) => RideStop.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  @override
  List<Object?> get props => [
    id,
    customerId,
    driverId,
    vehicleId,
    pickupAddress,
    pickupLatLng,
    dropoffAddress,
    dropoffLatLng,
    serviceType,
    estimatedDistance,
    estimatedDuration,
    estimatedPrice,
    finalPrice,
    status,
    createdAt,
    updatedAt,
    acceptedAt,
    startedAt,
    completedAt,
    cancelledAt,
    cancellationReason,
    passengerNote,
    rating,
    reviewText,
    stops,
  ];
}
