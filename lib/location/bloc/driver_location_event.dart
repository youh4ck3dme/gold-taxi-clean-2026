import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import '../driver_location_repository.dart';

abstract class DriverLocationEvent extends Equatable {
  const DriverLocationEvent();

  @override
  List<Object?> get props => [];
}

class InitializeDriverState extends DriverLocationEvent {
  final String driverId;

  const InitializeDriverState(this.driverId);

  @override
  List<Object?> get props => [driverId];
}

class ToggleOnline extends DriverLocationEvent {
  final String driverId;

  const ToggleOnline(this.driverId);

  @override
  List<Object?> get props => [driverId];
}

class UpdatePosition extends DriverLocationEvent {
  final Position position;

  const UpdatePosition(this.position);

  @override
  List<Object?> get props => [position];
}

class UpdateOnlineDrivers extends DriverLocationEvent {
  final List<DriverLocation> onlineDrivers;

  const UpdateOnlineDrivers(this.onlineDrivers);

  @override
  List<Object?> get props => [onlineDrivers];
}

class SetLocationError extends DriverLocationEvent {
  final String message;

  const SetLocationError(this.message);

  @override
  List<Object?> get props => [message];
}

class StartListeningToOnlineDrivers extends DriverLocationEvent {}

class StopListeningToOnlineDrivers extends DriverLocationEvent {}
