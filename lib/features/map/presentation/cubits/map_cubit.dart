import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';

import '../../../../models/driver_position_model.dart';
import '../../../map/data/repositories/driver_position_repository.dart';

/// Map State
abstract class MapState extends Equatable {
  const MapState();

  @override
  List<Object?> get props => [];
}

class MapInitial extends MapState {}

class MapLoading extends MapState {}

class MapLoaded extends MapState {
  final GoogleMapController? controller;
  final List<DriverPositionModel> drivers;
  final List<Marker> markers;
  final LatLng? currentPosition;
  final bool isTracking;
  final String? selectedDriverId;

  const MapLoaded({
    this.controller,
    this.drivers = const [],
    this.markers = const [],
    this.currentPosition,
    this.isTracking = false,
    this.selectedDriverId,
  });

  MapLoaded copyWith({
    GoogleMapController? controller,
    List<DriverPositionModel>? drivers,
    List<Marker>? markers,
    LatLng? currentPosition,
    bool? isTracking,
    String? selectedDriverId,
  }) {
    return MapLoaded(
      controller: controller ?? this.controller,
      drivers: drivers ?? this.drivers,
      markers: markers ?? this.markers,
      currentPosition: currentPosition ?? this.currentPosition,
      isTracking: isTracking ?? this.isTracking,
      selectedDriverId: selectedDriverId ?? this.selectedDriverId,
    );
  }

  @override
  List<Object?> get props => [
    controller,
    drivers,
    markers,
    currentPosition,
    isTracking,
    selectedDriverId,
  ];
}

class MapError extends MapState {
  final String message;

  const MapError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Map Cubit
class MapCubit extends Cubit<MapState> {
  final DriverPositionRepository _driverPositionRepository;
  final Logger _logger = Logger();

  MapCubit(this._driverPositionRepository) : super(MapInitial());

  /// Initialize map with realtime driver tracking
  void initMap(GoogleMapController controller) {
    _logger.i('🗺️ Initializing map with realtime tracking');

    // Listen to driver positions
    _driverPositionRepository.getDriverPositionsStream().listen(
      (drivers) {
        _updateMarkers(controller, drivers);
      },
      onError: (error) {
        _logger.e('Error in driver stream: $error');
        emit(const MapError('Failed to load driver positions'));
      },
    );

    emit(MapLoaded(controller: controller));
  }

  /// Update markers on map
  void _updateMarkers(
    GoogleMapController controller,
    List<DriverPositionModel> drivers,
  ) {
    final markers = <Marker>[];

    for (final driver in drivers) {
      markers.add(
        Marker(
          markerId: MarkerId(driver.driverId),
          position: LatLng(driver.lat, driver.lng),
          infoWindow: InfoWindow(
            title: driver.name,
            snippet:
                '${driver.serviceType} • ${driver.rating}★ • ${driver.carModel}',
          ),
          icon: kIsWeb
              ? BitmapDescriptor.defaultMarker
              : (driver.isAvailable
                    ? BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueGreen,
                      )
                    : BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      )),
          rotation: driver.bearing,
          onTap: () => selectDriver(driver.driverId),
        ),
      );
    }

    final currentState = state;
    if (currentState is MapLoaded) {
      emit(
        currentState.copyWith(
          controller: controller,
          drivers: drivers,
          markers: markers,
        ),
      );
    } else {
      emit(
        MapLoaded(controller: controller, drivers: drivers, markers: markers),
      );
    }
  }

  /// Select a driver
  void selectDriver(String? driverId) {
    final currentState = state;
    if (currentState is MapLoaded) {
      final selectedDriver = driverId != null
          ? currentState.drivers
                .where((d) => d.driverId == driverId)
                .firstOrNull
          : null;

      if (selectedDriver != null) {
        _moveCameraToDriver(selectedDriver);
      }

      emit(currentState.copyWith(selectedDriverId: driverId));
    }
  }

  /// Move camera to driver
  Future<void> _moveCameraToDriver(DriverPositionModel driver) async {
    final currentState = state;
    if (currentState is MapLoaded && currentState.controller != null) {
      await currentState.controller!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(driver.lat, driver.lng), 15.0),
      );
    }
  }

  /// Move camera to current position
  Future<void> moveToCurrentPosition(LatLng position) async {
    final currentState = state;
    if (currentState is MapLoaded && currentState.controller != null) {
      await currentState.controller!.animateCamera(
        CameraUpdate.newLatLngZoom(position, 14.0),
      );
      emit(currentState.copyWith(currentPosition: position));
    }
  }

  /// Update current position
  void updateCurrentPosition(LatLng position) {
    final currentState = state;
    if (currentState is MapLoaded) {
      emit(currentState.copyWith(currentPosition: position));
    }
  }

  /// Toggle tracking mode
  void toggleTracking(bool isTracking) {
    final currentState = state;
    if (currentState is MapLoaded) {
      emit(currentState.copyWith(isTracking: isTracking));
    }
  }

  /// Center on all drivers
  Future<void> centerOnAllDrivers() async {
    final currentState = state;
    if (currentState is MapLoaded) {
      final drivers = currentState.drivers;
      if (drivers.isNotEmpty && currentState.controller != null) {
        // Calculate bounds
        double minLat = drivers.first.lat;
        double maxLat = drivers.first.lat;
        double minLng = drivers.first.lng;
        double maxLng = drivers.first.lng;

        for (final driver in drivers) {
          minLat = driver.lat < minLat ? driver.lat : minLat;
          maxLat = driver.lat > maxLat ? driver.lat : maxLat;
          minLng = driver.lng < minLng ? driver.lng : minLng;
          maxLng = driver.lng > maxLng ? driver.lng : maxLng;
        }

        // Add padding
        const padding = 0.01;
        final bounds = LatLngBounds(
          southwest: LatLng(minLat - padding, minLng - padding),
          northeast: LatLng(maxLat + padding, maxLng + padding),
        );

        await currentState.controller!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100),
        );
      }
    }
  }

  /// Get nearest drivers to current position
  Future<List<DriverPositionModel>> getNearestDrivers({
    required double lat,
    required double lng,
    int limit = 5,
  }) async {
    return _driverPositionRepository.getNearestDrivers(
      lat: lat,
      lng: lng,
      limit: limit,
    );
  }
}
