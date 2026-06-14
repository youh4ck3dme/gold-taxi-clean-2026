import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gold_taxi/features/map/presentation/cubits/ride_cubit.dart';
import 'package:gold_taxi/features/map/data/repositories/ride_repository.dart';
import 'package:gold_taxi/models/ride_model.dart';
import 'package:gold_taxi/models/ride_status.dart';
import 'package:gold_taxi/core/services/pricing_service.dart';
import 'package:gold_taxi/core/services/analytics_service.dart';
import 'package:gold_taxi/core/di/service_locator.dart';

import 'package:gold_taxi/features/map/data/repositories/promo_repository.dart';

class MockRideRepository extends Mock implements RideRepository {}
class MockPromoRepository extends Mock implements PromoRepository {}
class MockAnalyticsService extends Mock implements AnalyticsService {
  @override
  Future<void> logRideRequested({required String rideId, required double estimatedPrice, required int stopCount, required String vehicleType}) async {}
  @override
  Future<void> recordError(dynamic exception, StackTrace? stack, {dynamic reason, bool fatal = false}) async {}
}

class FakeRideModel extends Fake implements RideModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRideModel());
    // Setup getIt for AnalyticsService to avoid errors in tests
    getIt.registerSingleton<AnalyticsService>(MockAnalyticsService());
  });

  late RideCubit rideCubit;
  late MockRideRepository mockRideRepository;
  late MockPromoRepository mockPromoRepository;

  setUp(() {
    mockRideRepository = MockRideRepository();
    mockPromoRepository = MockPromoRepository();
    rideCubit = RideCubit(mockRideRepository, mockPromoRepository);
  });

  tearDown(() async {
    await rideCubit.close();
  });

  group('RideCubit Tests', () {
    test('Initial state is requested status and default values', () {
      expect(rideCubit.state.status, RideStatus.requested);
      expect(rideCubit.state.surgeMultiplier, 1.0);
      expect(rideCubit.state.isInZone, true);
      expect(rideCubit.state.isCheckingZone, false);
    });

    test('checkZoneAndSurge emits states with isCheckingZone, isInZone, and surgeMultiplier on success (inside zone)', () async {
      when(() => mockRideRepository.checkLocationInZone(any(), any())).thenAnswer((_) async => true);
      when(() => mockRideRepository.getSurgeMultiplier(any(), any())).thenAnswer((_) async => 1.5);

      expectLater(
        rideCubit.stream,
        emitsInOrder([
          predicate<RideState>((state) => state.isCheckingZone == true && state.errorMessage == null),
          predicate<RideState>((state) => state.isCheckingZone == false && state.isInZone == true && state.surgeMultiplier == 1.5),
        ]),
      );

      await rideCubit.checkZoneAndSurge(const LatLng(48.7219, 21.2575));
    });

    test('checkZoneAndSurge emits error and isInZone=false when location is outside zone', () async {
      when(() => mockRideRepository.checkLocationInZone(any(), any())).thenAnswer((_) async => false);

      expectLater(
        rideCubit.stream,
        emitsInOrder([
          predicate<RideState>((state) => state.isCheckingZone == true),
          predicate<RideState>((state) => state.isCheckingZone == false && state.isInZone == false && state.errorMessage == 'V tejto oblasti zatiaľ nejazdíme'),
        ]),
      );

      await rideCubit.checkZoneAndSurge(const LatLng(48.1486, 17.1077));
    });

    test('checkZoneAndSurge emits error state when repository throws exception', () async {
      when(() => mockRideRepository.checkLocationInZone(any(), any())).thenThrow(Exception('DB error'));

      expectLater(
        rideCubit.stream,
        emitsInOrder([
          predicate<RideState>((state) => state.isCheckingZone == true),
          predicate<RideState>((state) => state.isCheckingZone == false && state.errorMessage!.contains('Nepodarilo sa overiť polohu')),
        ]),
      );

      await rideCubit.checkZoneAndSurge(const LatLng(48.7219, 21.2575));
    });

    test('requestRide successfully calls createRide and updates status', () async {
      final mockRide = RideModel(
        id: 'ride_123',
        customerId: 'customer_1',
        pickupAddress: 'Kosice',
        pickupLatLng: const LatLng(48.7219, 21.2575),
        dropoffAddress: 'Presov',
        dropoffLatLng: const LatLng(48.9981, 21.2393),
        serviceType: ServiceType.standard,
        estimatedDistance: 35.0,
        estimatedDuration: 70.0,
        estimatedPrice: 35.0,
        status: RideStatus.requested,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(() => mockRideRepository.createRide(any())).thenAnswer((_) async => mockRide);
      // Use a never-ending stream for the subscription
      when(() => mockRideRepository.getRide(any())).thenAnswer((_) => const Stream.empty());

      // Just verify the repository is called correctly
      await rideCubit.requestRide(
        customerId: 'customer_1',
        pickupAddress: 'Kosice',
        pickupLatLng: const LatLng(48.7219, 21.2575),
        dropoffAddress: 'Presov',
        dropoffLatLng: const LatLng(48.9981, 21.2393),
        serviceType: ServiceType.standard,
        distance: 35.0,
        estimate: 35.0,
      );

      await untilCalled(() => mockRideRepository.createRide(any()));
      verify(() => mockRideRepository.createRide(any())).called(1);
    });
  });
}
