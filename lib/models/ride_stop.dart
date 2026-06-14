import '../core/services/mock_geocoding_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RideStop {
  final String id;
  final LocationModel location;
  final bool isWaitingEnabled;
  final int waitingMinutes;
  final String status; // 'pending', 'arrived', 'waiting', 'completed'

  const RideStop({
    required this.id,
    required this.location,
    this.isWaitingEnabled = false,
    this.waitingMinutes = 0,
    this.status = 'pending',
  });

  RideStop copyWith({
    String? id,
    LocationModel? location,
    bool? isWaitingEnabled,
    int? waitingMinutes,
    String? status,
  }) {
    return RideStop(
      id: id ?? this.id,
      location: location ?? this.location,
      isWaitingEnabled: isWaitingEnabled ?? this.isWaitingEnabled,
      waitingMinutes: waitingMinutes ?? this.waitingMinutes,
      status: status ?? this.status,
    );
  }

  factory RideStop.fromJson(Map<String, dynamic> json) {
    return RideStop(
      id: json['id'] as String? ?? '',
      location: LocationModel(
        name: json['name'] as String? ?? '',
        address: json['address'] as String? ?? '',
        position: LatLng(
          (json['lat'] as num?)?.toDouble() ?? 0.0,
          (json['lng'] as num?)?.toDouble() ?? 0.0,
        ),
      ),
      isWaitingEnabled: json['is_waiting_enabled'] as bool? ?? false,
      waitingMinutes: json['waiting_minutes'] as int? ?? 0,
      status: json['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': location.name,
      'address': location.address,
      'lat': location.position.latitude,
      'lng': location.position.longitude,
      'is_waiting_enabled': isWaitingEnabled,
      'waiting_minutes': waitingMinutes,
      'status': status,
    };
  }
}
