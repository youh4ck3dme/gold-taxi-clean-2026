import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../driver_location_repository.dart';
import 'driver_location_event.dart';
import 'driver_location_state.dart';

class DriverLocationBloc extends Bloc<DriverLocationEvent, DriverLocationState> {
  final DriverLocationRepository _repository;

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<List<DriverLocation>>? _driversSubscription;

  DriverLocationBloc({DriverLocationRepository? repository})
      : _repository = repository ?? DriverLocationRepository(),
        super(const DriverLocationState()) {
    on<InitializeDriverState>(_onInitializeDriverState);
    on<ToggleOnline>(_onToggleOnline);
    on<UpdatePosition>(_onUpdatePosition);
    on<UpdateOnlineDrivers>(_onUpdateOnlineDrivers);
    on<SetLocationError>(_onSetLocationError);
    on<StartListeningToOnlineDrivers>(_onStartListeningToOnlineDrivers);
    on<StopListeningToOnlineDrivers>(_onStopListeningToOnlineDrivers);
  }

  Future<void> _onInitializeDriverState(
    InitializeDriverState event,
    Emitter<DriverLocationState> emit,
  ) async {
    try {
      final state = await _repository.getDriverLocation(event.driverId);
      if (state != null) {
        emit(this.state.copyWith(isOnline: state.isOnline));
        if (state.isOnline) {
          await _startTracking(event.driverId);
        }
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onToggleOnline(
    ToggleOnline event,
    Emitter<DriverLocationState> emit,
  ) async {
    final nextOnline = !state.isOnline;
    emit(state.copyWith(isOnline: nextOnline, clearError: true));

    try {
      await _repository.toggleOnlineStatus(event.driverId, nextOnline);
      if (nextOnline) {
        await _startTracking(event.driverId);
      } else {
        _stopTracking();
        emit(state.copyWith(isOnline: false, clearPosition: true));
      }
    } catch (e) {
      // Revert state on failure
      emit(state.copyWith(
        isOnline: !nextOnline,
        errorMessage: 'Chyba pri zmene stavu: ${e.toString()}',
      ));
      _stopTracking();
    }
  }

  void _onUpdatePosition(
    UpdatePosition event,
    Emitter<DriverLocationState> emit,
  ) {
    emit(state.copyWith(currentPosition: event.position));
  }

  void _onUpdateOnlineDrivers(
    UpdateOnlineDrivers event,
    Emitter<DriverLocationState> emit,
  ) {
    emit(state.copyWith(onlineDrivers: event.onlineDrivers));
  }

  void _onSetLocationError(
    SetLocationError event,
    Emitter<DriverLocationState> emit,
  ) {
    emit(state.copyWith(errorMessage: event.message));
  }

  void _onStartListeningToOnlineDrivers(
    StartListeningToOnlineDrivers event,
    Emitter<DriverLocationState> emit,
  ) {
    _driversSubscription?.cancel();
    _driversSubscription = _repository.streamOnlineDrivers().listen(
      (drivers) {
        add(UpdateOnlineDrivers(drivers));
      },
      onError: (error) {
        add(SetLocationError('Chyba načítavania vodičov: ${error.toString()}'));
      },
    );
  }

  void _onStopListeningToOnlineDrivers(
    StopListeningToOnlineDrivers event,
    Emitter<DriverLocationState> emit,
  ) {
    _driversSubscription?.cancel();
    _driversSubscription = null;
    emit(state.copyWith(onlineDrivers: const []));
  }

  Future<void> _startTracking(String driverId) async {
    _positionSubscription?.cancel();

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      add(const SetLocationError('Služby určovania polohy sú vypnuté.'));
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        add(const SetLocationError('Prístup k polohe bol zamietnutý.'));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      add(const SetLocationError(
        'Prístup k polohe je trvalo zamietnutý. Prosím, povoľte ho v nastaveniach.',
      ));
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      add(UpdatePosition(position));
      await _repository.updateLocation(driverId, position.latitude, position.longitude);
    } catch (e) {
      // Ignored initially
    }

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (Position position) async {
        add(UpdatePosition(position));
        try {
          await _repository.updateLocation(
            driverId,
            position.latitude,
            position.longitude,
          );
        } catch (e) {
          // Ignored
        }
      },
      onError: (error) {
        add(SetLocationError('Chyba GPS: ${error.toString()}'));
      },
    );
  }

  void _stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  @override
  Future<void> close() {
    _positionSubscription?.cancel();
    _driversSubscription?.cancel();
    return super.close();
  }
}
