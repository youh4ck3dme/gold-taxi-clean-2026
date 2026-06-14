import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold_taxi/features/map/presentation/pages/ride_request_page.dart';
import 'package:gold_taxi/features/map/presentation/cubits/ride_cubit.dart';
import 'package:gold_taxi/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:gold_taxi/features/auth/presentation/cubits/auth_state.dart';
import 'package:gold_taxi/features/profile/presentation/pages/customer_profile_page.dart';
import 'package:gold_taxi/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:gold_taxi/features/profile/presentation/bloc/profile_state.dart';
import 'package:gold_taxi/models/user_model.dart';
import 'package:gold_taxi/core/services/mock_geocoding_service.dart';
import 'package:gold_taxi/models/promo_code_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gold_taxi/core/di/service_locator.dart';
import 'package:gold_taxi/models/ride_status.dart';

class MockRideCubit extends Mock implements RideCubit {}
class MockProfileCubit extends Mock implements ProfileCubit {}
class MockAuthCubit extends Mock implements AuthCubit {}

void main() {
  late MockRideCubit mockRideCubit;
  late MockProfileCubit mockProfileCubit;
  late MockAuthCubit mockAuthCubit;

  setUpAll(() {
    // Register mock dependencies in getIt if needed
    getIt.allowReassignment = true;
  });

  setUp(() {
    mockRideCubit = MockRideCubit();
    mockProfileCubit = MockProfileCubit();
    mockAuthCubit = MockAuthCubit();

    // Default stubbing
    when(() => mockRideCubit.state).thenReturn(RideState(status: RideStatus.requested));
    when(() => mockRideCubit.stream).thenAnswer((_) => Stream.value(RideState(status: RideStatus.requested)));
    
    when(() => mockAuthCubit.state).thenReturn(const Authenticated(
      UserModel(
        id: 'dev_user_123',
        name: 'Developer',
        email: 'dev@localhost',
        role: 'customer',
        referralCode: 'JOZO50',
      ),
    ));
    when(() => mockAuthCubit.stream).thenAnswer((_) => Stream.value(const Authenticated(
      UserModel(
        id: 'dev_user_123',
        name: 'Developer',
        email: 'dev@localhost',
        role: 'customer',
        referralCode: 'JOZO50',
      ),
    )));

    when(() => mockProfileCubit.state).thenReturn(const ProfileLoaded(
      user: UserModel(
        id: 'dev_user_123',
        name: 'Developer',
        email: 'dev@localhost',
        role: 'customer',
        referralCode: 'JOZO50',
      ),
      orders: [],
      bookings: [],
    ));
    when(() => mockProfileCubit.stream).thenAnswer((_) => Stream.value(const ProfileLoaded(
      user: UserModel(
        id: 'dev_user_123',
        name: 'Developer',
        email: 'dev@localhost',
        role: 'customer',
        referralCode: 'JOZO50',
      ),
      orders: [],
      bookings: [],
    )));

    when(() => mockRideCubit.checkZoneAndSurge(any())).thenAnswer((_) async {});

    // Register cubits in locator for pages that look them up via getIt
    getIt.registerSingleton<AuthCubit>(mockAuthCubit);
  });

  tearDown(() {
    getIt.reset();
  });

  group('Promo & Referral UI Tests', () {
    testWidgets('1. RideRequestPage displays "Zadať kód" button and opens PromoDialog', (WidgetTester tester) async {
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
                  name: 'Aupark Košice',
                  address: 'Námestie osloboditeľov 1, 040 01 Košice',
                  position: LatLng(48.7186, 21.2625),
                ),
              ),
            ),
          ),
        ),
      );

      // Verify page has "Zadať kód" button
      expect(find.text('Zadať kód'), findsOneWidget);

      // Tap "Zadať kód" to open dialog
      await tester.tap(find.text('Zadať kód'));
      await tester.pumpAndSettle();

      // Verify Dialog opens
      expect(find.text('Zadať promo kód'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Použiť'), findsOneWidget);

      // Enter code and submit
      await tester.enterText(find.byType(TextField), 'TAXI5');
      
      when(() => mockRideCubit.validateAndApplyPromo('TAXI5', 'dev_user_123', any()))
          .thenAnswer((_) async {});

      await tester.tap(find.text('Použiť'));
      await tester.pumpAndSettle();

      // Verify validateAndApplyPromo is called
      verify(() => mockRideCubit.validateAndApplyPromo('TAXI5', 'dev_user_123', any())).called(1);
    });

    testWidgets('2. CustomerProfilePage renders referral code and share button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<ProfileCubit>.value(value: mockProfileCubit),
                BlocProvider<AuthCubit>.value(value: mockAuthCubit),
              ],
              child: const CustomerProfilePage(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify "Odporuč a zarob" card elements are displayed
      expect(find.text('Odporuč a zarob'), findsOneWidget);
      expect(find.text('JOZO50'), findsOneWidget);
      expect(find.text('Zdieľať'), findsOneWidget);

      // Verify referred_by input field is displayed when referredBy is null
      expect(find.text('Bol si odporúčaný? Zadaj kód priateľa:'), findsOneWidget);
      expect(find.text('Uplatniť'), findsOneWidget);
    });

    testWidgets('3. CustomerProfilePage handles applying referral code successfully', (WidgetTester tester) async {
      when(() => mockProfileCubit.applyReferralCode('MICHAL80'))
          .thenAnswer((_) async => null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<ProfileCubit>.value(value: mockProfileCubit),
                BlocProvider<AuthCubit>.value(value: mockAuthCubit),
              ],
              child: const CustomerProfilePage(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final inputField = find.ancestor(
        of: find.text('Napr. JOZO50'),
        matching: find.byType(TextField),
      );
      
      await tester.enterText(inputField, 'MICHAL80');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Uplatniť'));
      await tester.pumpAndSettle();

      verify(() => mockProfileCubit.applyReferralCode('MICHAL80')).called(1);
    });
  });
}
