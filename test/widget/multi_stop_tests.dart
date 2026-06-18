import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold_taxi/features/map/presentation/pages/ride_request_page.dart';
import 'package:gold_taxi/features/map/presentation/cubits/ride_cubit.dart';
import 'package:gold_taxi/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:gold_taxi/features/auth/presentation/cubits/auth_state.dart';
import 'package:gold_taxi/models/user_model.dart';
import 'package:gold_taxi/core/services/mock_geocoding_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gold_taxi/core/di/service_locator.dart';
import 'package:gold_taxi/models/ride_status.dart';
import 'package:gold_taxi/models/ride_stop.dart';

class MockRideCubit extends Mock implements RideCubit {}

class MockAuthCubit extends Mock implements AuthCubit {}

void main() {
  late MockRideCubit mockRideCubit;
  late MockAuthCubit mockAuthCubit;

  setUpAll(() {
    getIt.allowReassignment = true;
  });

  setUp(() {
    mockRideCubit = MockRideCubit();
    mockAuthCubit = MockAuthCubit();

    when(() => mockRideCubit.state).thenReturn(
      RideState(
        status: RideStatus.requested,
        intermediateStops: [
          const RideStop(
            id: 'stop_1',
            location: LocationModel(
              name: 'Aupark Košice',
              address: 'Námestie osloboditeľov 1, Košice',
              position: LatLng(48.7188, 21.2614),
            ),
            isWaitingEnabled: true,
            waitingMinutes: 10,
          ),
        ],
      ),
    );
    when(
      () => mockRideCubit.stream,
    ).thenAnswer((_) => Stream.value(mockRideCubit.state));

    when(() => mockAuthCubit.state).thenReturn(
      const Authenticated(
        UserModel(
          id: 'dev_user_123',
          name: 'Developer',
          email: 'dev@localhost',
          role: UserRole.customer,
        ),
      ),
    );
    when(
      () => mockAuthCubit.stream,
    ).thenAnswer((_) => Stream.value(mockAuthCubit.state));
    when(() => mockRideCubit.checkZoneAndSurge(any())).thenAnswer((_) async {});

    getIt.registerSingleton<AuthCubit>(mockAuthCubit);
  });

  tearDown(() {
    getIt.reset();
  });

  group('Multi-Stop & Wait for me Widget Tests', () {
    testWidgets(
      '1. Timeline renders intermediate stops and "Wait for me" details',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MultiBlocProvider(
                providers: [
                  BlocProvider<RideCubit>.value(value: mockRideCubit),
                  BlocProvider<AuthCubit>.value(value: mockAuthCubit),
                ],
                child: const RideRequestPage(
                  destination: LocationModel(
                    name: 'Steel Aréna',
                    address: 'Nerudova 12, Košice',
                    position: LatLng(48.7154, 21.2492),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check Timeline elements
        expect(find.text('Plánovanie trasy a zastávky'), findsOneWidget);
        expect(find.text('Štart'), findsOneWidget);
        expect(find.text('Cieľ'), findsOneWidget);

        // Check intermediate stop
        expect(find.text('Aupark Košice'), findsOneWidget);
        expect(find.text('Počkaj ma:'), findsOneWidget);

        // Verify Slider and wait time text is displayed
        expect(find.byType(Slider), findsOneWidget);
        expect(find.text('10 min (+3.00 €)'), findsOneWidget);
      },
    );

    testWidgets('2. Toggle wait time triggers toggling cubit state', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(
        () => mockRideCubit.toggleWaitTime('stop_1', false, 0),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<RideCubit>.value(value: mockRideCubit),
                BlocProvider<AuthCubit>.value(value: mockAuthCubit),
              ],
              child: const RideRequestPage(
                destination: LocationModel(
                  name: 'Steel Aréna',
                  address: 'Nerudova 12, Košice',
                  position: LatLng(48.7154, 21.2492),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find switch
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      // Tap switch to disable waiting
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      verify(() => mockRideCubit.toggleWaitTime('stop_1', false, 0)).called(1);
    });
  });
}
