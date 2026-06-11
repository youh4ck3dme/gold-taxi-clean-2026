import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import '../driver_location_repository.dart';

class DriverLocationState extends Equatable {
  final bool isOnline;
  final Position? currentPosition;
  final List<DriverLocation> onlineDrivers;
  final String? errorMessage;

  const DriverLocationState({
    this.isOnline = false,
    this.currentPosition,
    this.onlineDrivers = const [],
    this.errorMessage,
  });

  DriverLocationState copyWith({
    bool? isOnline,
    Position? currentPosition,
    List<DriverLocation>? onlineDrivers,
    String? errorMessage,
    bool clearPosition = false,
    bool clearError = false,
  }) {
    return DriverLocationState(
      isOnline: isOnline ?? this.isOnline,
      currentPosition: clearPosition ? null : (currentPosition ?? this.currentPosition),
      onlineDrivers: onlineDrivers ?? this.onlineDrivers,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [isOnline, currentPosition, onlineDrivers, errorMessage];
}
