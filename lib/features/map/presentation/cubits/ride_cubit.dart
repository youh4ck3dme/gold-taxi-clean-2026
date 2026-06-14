import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../models/ride_stop.dart';
import '../../../../models/ride_status.dart';
import '../../../../models/ride_model.dart';
import '../../../../models/driver_position_model.dart';
import '../../../../models/promo_code_model.dart';
import '../../../../core/services/pricing_service.dart';
import '../../../../core/services/mock_geocoding_service.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../data/repositories/ride_repository.dart';
import '../../data/repositories/promo_repository.dart';
import 'dart:async';

class RideState {
  final RideStatus status;
  final RideModel? currentRide;
  final DriverPositionModel? driver;
  final String? errorMessage;
  final double surgeMultiplier;
  final bool isInZone;
  final bool isCheckingZone;
  final PromoCodeModel? appliedPromo;
  final String? promoError;
  final List<RideStop> intermediateStops;

  RideState({
    required this.status,
    this.currentRide,
    this.driver,
    this.errorMessage,
    this.surgeMultiplier = 1.0,
    this.isInZone = true,
    this.isCheckingZone = false,
    this.appliedPromo,
    this.promoError,
    this.intermediateStops = const [],
  });

  RideState copyWith({
    RideStatus? status,
    RideModel? currentRide,
    DriverPositionModel? driver,
    String? errorMessage,
    double? surgeMultiplier,
    bool? isInZone,
    bool? isCheckingZone,
    PromoCodeModel? appliedPromo,
    bool clearPromo = false,
    String? promoError,
    bool clearPromoError = false,
    List<RideStop>? intermediateStops,
  }) {
    return RideState(
      status: status ?? this.status,
      currentRide: currentRide ?? this.currentRide,
      driver: driver ?? this.driver,
      errorMessage: errorMessage ?? this.errorMessage,
      surgeMultiplier: surgeMultiplier ?? this.surgeMultiplier,
      isInZone: isInZone ?? this.isInZone,
      isCheckingZone: isCheckingZone ?? this.isCheckingZone,
      appliedPromo: clearPromo ? null : (appliedPromo ?? this.appliedPromo),
      promoError: clearPromoError ? null : (promoError ?? this.promoError),
      intermediateStops: intermediateStops ?? this.intermediateStops,
    );
  }
}

class RideCubit extends Cubit<RideState> {
  final RideRepository _rideRepository;
  final PromoRepository _promoRepository;
  StreamSubscription? _rideSubscription;
  Timer? _simulationTimer;

  RideCubit(this._rideRepository, this._promoRepository)
      : super(RideState(status: RideStatus.requested));

  Future<void> checkZoneAndSurge(LatLng pickup) async {
    emit(state.copyWith(
      isCheckingZone: true,
      errorMessage: null,
      isInZone: true,
      surgeMultiplier: 1.0,
    ));
    try {
      final inZone = await _rideRepository.checkLocationInZone(pickup.latitude, pickup.longitude);
      if (!inZone) {
        emit(state.copyWith(
          isCheckingZone: false,
          isInZone: false,
          errorMessage: 'V tejto oblasti zatiaľ nejazdíme',
        ));
        return;
      }
      final multiplier = await _rideRepository.getSurgeMultiplier(pickup.latitude, pickup.longitude);
      emit(state.copyWith(
        isCheckingZone: false,
        isInZone: true,
        surgeMultiplier: multiplier,
      ));
    } catch (e) {
      emit(state.copyWith(
        isCheckingZone: false,
        errorMessage: 'Nepodarilo sa overiť polohu: $e',
      ));
    }
  }

  Future<void> validateAndApplyPromo(String code, String userId, double rideAmount) async {
    emit(state.copyWith(clearPromoError: true));
    try {
      final result = await _promoRepository.validatePromoCode(
        code: code,
        userId: userId,
        rideAmount: rideAmount,
      );
      if (result.isValid) {
        emit(state.copyWith(
          appliedPromo: result,
          clearPromoError: true,
        ));
      } else {
        emit(state.copyWith(
          promoError: result.errorMessage ?? 'Neplatný kód',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        promoError: 'Chyba overenia: $e',
      ));
    }
  }

  void removePromoCode() {
    emit(state.copyWith(
      clearPromo: true,
      clearPromoError: true,
    ));
  }

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
      stops: state.intermediateStops,
    );

    try {
      final createdRide = await _rideRepository.createRide(ride);
      
      // Use promo code in repository if one is applied
      if (state.appliedPromo != null) {
        await _promoRepository.usePromoCode(
          code: state.appliedPromo!.code,
          userId: customerId,
          rideId: createdRide.id,
        );
      }

      // Log Analytics Event
      await getIt<AnalyticsService>().logRideRequested(
        rideId: createdRide.id,
        estimatedPrice: createdRide.estimatedPrice,
        stopCount: createdRide.stops.length,
        vehicleType: createdRide.serviceType.name,
      );

      emit(state.copyWith(
        status: RideStatus.requested,
        currentRide: createdRide,
        clearPromo: true,
        clearPromoError: true,
      ));
      _subscribeToRide(createdRide.id);
      
      // For demo, we still trigger the simulation if it's a mock repo
      startRideSimulation(createdRide.id);
    } catch (e, stack) {
      await getIt<AnalyticsService>().recordError(e, stack, reason: 'Failed to create ride request');
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

  void addIntermediateStop(LocationModel location) {
    if (state.intermediateStops.length >= 3) {
      emit(state.copyWith(promoError: 'Maximálne je možné pridať 3 zastávky.'));
      return;
    }
    final uuid = const Uuid().v4();
    final newStop = RideStop(
      id: uuid,
      location: location,
    );
    final updatedStops = List<RideStop>.from(state.intermediateStops)..add(newStop);
    emit(state.copyWith(intermediateStops: updatedStops));
  }

  void removeIntermediateStop(String stopId) {
    final updatedStops = state.intermediateStops.where((s) => s.id != stopId).toList();
    emit(state.copyWith(intermediateStops: updatedStops));
  }

  void reorderStops(int oldIndex, int newIndex) {
    var index = newIndex;
    if (oldIndex < index) {
      index -= 1;
    }
    final updatedStops = List<RideStop>.from(state.intermediateStops);
    final item = updatedStops.removeAt(oldIndex);
    updatedStops.insert(index, item);
    emit(state.copyWith(intermediateStops: updatedStops));
  }

  void toggleWaitTime(String stopId, bool enabled, int minutes) {
    final updatedStops = state.intermediateStops.map((s) {
      if (s.id == stopId) {
        return s.copyWith(
          isWaitingEnabled: enabled,
          waitingMinutes: minutes,
        );
      }
      return s;
    }).toList();
    emit(state.copyWith(intermediateStops: updatedStops));
  }

  @override
  Future<void> close() {
    _simulationTimer?.cancel();
    _rideSubscription?.cancel();
    return super.close();
  }
}
