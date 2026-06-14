import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../models/ride_status.dart';
import '../../../../models/ride_model.dart';
import '../../../../models/driver_position_model.dart';
import '../../../../core/services/pricing_service.dart';
import '../../data/repositories/ride_repository.dart';
import 'dart:async';

class RideState {
  final RideStatus status;
  final RideModel? currentRide;
  final DriverPositionModel? driver;
  final String? errorMessage;

  RideState({
    required this.status,
    this.currentRide,
    this.driver,
    this.errorMessage,
  });

  RideState copyWith({
    RideStatus? status,
    RideModel? currentRide,
    DriverPositionModel? driver,
    String? errorMessage,
  }) {
    return RideState(
      status: status ?? this.status,
      currentRide: currentRide ?? this.currentRide,
      driver: driver ?? this.driver,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class RideCubit extends Cubit<RideState> {
  final RideRepository _rideRepository;
  StreamSubscription? _rideSubscription;
  Timer? _simulationTimer;

  RideCubit(this._rideRepository) : super(RideState(status: RideStatus.requested));

  Future<void> requestRide({
    required String customerId,
    required String pickupAddress,
    required LatLng pickupLatLng,
    required String dropoffAddress,
    required LatLng dropoffLatLng,
    required ServiceType serviceType,
    required double distance,
    required double estimate,
  }) async {
    final ride = RideModel(
      id: const Uuid().v4(),
      customerId: customerId,
      pickupAddress: pickupAddress,
      pickupLatLng: pickupLatLng,
      dropoffAddress: dropoffAddress,
      dropoffLatLng: dropoffLatLng,
      serviceType: serviceType,
      estimatedDistance: distance,
      estimatedDuration: distance * 2, // Mock 2 min per km
      estimatedPrice: estimate,
      status: RideStatus.requested,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      final createdRide = await _rideRepository.createRide(ride);
      emit(state.copyWith(status: RideStatus.requested, currentRide: createdRide));
      _subscribeToRide(createdRide.id);
      
      // For demo, we still trigger the simulation if it's a mock repo
      startRideSimulation(createdRide.id);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  void _subscribeToRide(String rideId) {
    _rideSubscription?.cancel();
    _rideSubscription = _rideRepository.getRide(rideId).listen((ride) {
      if (ride != null) {
        emit(state.copyWith(status: ride.status, currentRide: ride));
      }
    });
  }

  void startRideSimulation(String rideId) {
    _simulationTimer?.cancel();
    // 1. Requested (already done)

    // 2. Accept after 2 seconds
    _simulationTimer = Timer(const Duration(seconds: 2), () async {
      final mockDriver = DriverPositionModel(
        driverId: 'driver_1',
        name: 'Ján Kováč',
        lat: 48.7250,
        lng: 21.2500,
        bearing: 0,
        isAvailable: false,
        avatar: 'https://i.pravatar.cc/150?u=driver1',
        rating: 4.9,
        carModel: 'Škoda Superb',
        carPlate: 'KE-123AB',
        phone: '+421900111222',
        serviceType: 'Standard',
        lastUpdated: DateTime.now(),
      );
      
      await _rideRepository.acceptRide(rideId, 'driver_1');
      emit(state.copyWith(driver: mockDriver));

      // 3. Arriving after 4 seconds
      _simulationTimer = Timer(const Duration(seconds: 4), () {
        updateStatus(RideStatus.driverArriving);

        // 4. In Progress after 3 seconds
        _simulationTimer = Timer(const Duration(seconds: 3), () {
          updateStatus(RideStatus.inProgress);

          // 5. Completed after 5 seconds
          _simulationTimer = Timer(const Duration(seconds: 5), () {
            updateStatus(RideStatus.completed);
          });
        });
      });
    });
  }

  Future<void> updateStatus(RideStatus newStatus) async {
    final rideId = state.currentRide?.id;
    if (rideId == null) return;

    // Enforce transitions
    if (!_isValidTransition(state.status, newStatus)) {
      emit(state.copyWith(errorMessage: 'Neplatný prechod stavu: ${state.status.name} -> ${newStatus.name}'));
      return;
    }

    try {
      await _rideRepository.updateRideStatus(rideId, newStatus);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  bool _isValidTransition(RideStatus current, RideStatus next) {
    if (next == RideStatus.cancelled) return current.canCancel;
    
    switch (current) {
      case RideStatus.requested:
        return next == RideStatus.accepted;
      case RideStatus.accepted:
        return next == RideStatus.driverArriving;
      case RideStatus.driverArriving:
        return next == RideStatus.inProgress;
      case RideStatus.inProgress:
        return next == RideStatus.completed;
      case RideStatus.completed:
      case RideStatus.cancelled:
        return false;
    }
  }

  void cancelRide({String? reason}) {
    if (state.status.canCancel) {
      _simulationTimer?.cancel();
      updateStatus(RideStatus.cancelled);
    }
  }

  @override
  Future<void> close() {
    _simulationTimer?.cancel();
    _rideSubscription?.cancel();
    return super.close();
  }
}
