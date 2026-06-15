import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gold_taxi/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:gold_taxi/features/profile/presentation/bloc/profile_state.dart';
import 'package:gold_taxi/features/profile/data/repositories/profile_repository.dart';
import 'package:gold_taxi/models/user_model.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late ProfileCubit profileCubit;
  late MockProfileRepository mockProfileRepository;

  setUp(() {
    mockProfileRepository = MockProfileRepository();
    profileCubit = ProfileCubit(mockProfileRepository);
  });

  tearDown(() async {
    await profileCubit.close();
  });

  group('ProfileCubit Tests', () {
    const testCustomer = UserModel(
      id: '1',
      name: 'Customer Erik',
      email: 'erik@goldtaxi.com',
      role: 'customer',
    );

    const testDriver = UserModel(
      id: '2',
      name: 'Driver Erik',
      email: 'driver@goldtaxi.com',
      role: 'driver',
    );

    test('Initial state is ProfileInitial', () {
      expect(profileCubit.state, isA<ProfileInitial>());
    });

    test('fetchProfile emits [ProfileLoading, ProfileLoaded] for customer', () async {
      when(() => mockProfileRepository.getUserProfile()).thenAnswer((_) async => testCustomer);
      when(() => mockProfileRepository.getOrderHistory(any())).thenAnswer((_) async => []);
      when(() => mockProfileRepository.getBookingHistory(any())).thenAnswer((_) async => []);

      expectLater(
        profileCubit.stream,
        emitsInOrder([
          isA<ProfileLoading>(),
          isA<ProfileLoaded>(),
        ]),
      );

      await profileCubit.fetchProfile();
    });

    test('fetchProfile emits [ProfileLoading, ProfileLoaded] with driverStats for driver', () async {
      when(() => mockProfileRepository.getUserProfile()).thenAnswer((_) async => testDriver);
      when(() => mockProfileRepository.getOrderHistory(any())).thenAnswer((_) async => []);
      when(() => mockProfileRepository.getBookingHistory(any())).thenAnswer((_) async => []);
      when(() => mockProfileRepository.getDriverRecord(any())).thenAnswer((_) async => {
        'id': 'driver-uuid-123',
        'is_online': true,
        'vehicle_type': 'Škoda Octavia',
        'vehicle_plate': 'KE-123AB',
      });
      when(() => mockProfileRepository.getDriverStats(any())).thenAnswer((_) async => {
        'totalRides': 42,
        'totalEarnings': 1250.50,
        'averageRating': 4.7,
      });
      when(() => mockProfileRepository.getDriverDocuments(any())).thenAnswer((_) async => <String, dynamic>{});

      expectLater(
        profileCubit.stream,
        emitsInOrder([
          isA<ProfileLoading>(),
          predicate<ProfileState>((state) {
            if (state is! ProfileLoaded) return false;
            expect(state.driverStats, isNotNull);
            expect(state.driverStats!['totalRides'], 42);
            expect(state.driverStats!['totalEarnings'], 1250.50);
            expect(state.driverStats!['averageRating'], 4.7);
            return true;
          }),
        ]),
      );

      await profileCubit.fetchProfile();

      verify(() => mockProfileRepository.getDriverStats('driver-uuid-123')).called(1);
    });

    test('fetchProfile works when driver has no completed rides (empty stats)', () async {
      when(() => mockProfileRepository.getUserProfile()).thenAnswer((_) async => testDriver);
      when(() => mockProfileRepository.getOrderHistory(any())).thenAnswer((_) async => []);
      when(() => mockProfileRepository.getBookingHistory(any())).thenAnswer((_) async => []);
      when(() => mockProfileRepository.getDriverRecord(any())).thenAnswer((_) async => {
        'id': 'driver-uuid-456',
        'is_online': false,
      });
      when(() => mockProfileRepository.getDriverStats(any())).thenAnswer((_) async => {
        'totalRides': 0,
        'totalEarnings': 0.0,
        'averageRating': null,
      });
      when(() => mockProfileRepository.getDriverDocuments(any())).thenAnswer((_) async => <String, dynamic>{});

      expectLater(
        profileCubit.stream,
        emitsInOrder([
          isA<ProfileLoading>(),
          predicate<ProfileState>((state) {
            if (state is! ProfileLoaded) return false;
            expect(state.driverStats, isNotNull);
            expect(state.driverStats!['totalRides'], 0);
            expect(state.driverStats!['totalEarnings'], 0.0);
            expect(state.driverStats!['averageRating'], isNull);
            return true;
          }),
        ]),
      );

      await profileCubit.fetchProfile();
    });

    test('fetchProfile emits [ProfileLoading, ProfileError] when repository fails', () async {
      when(() => mockProfileRepository.getUserProfile()).thenThrow(Exception('API error'));

      expectLater(
        profileCubit.stream,
        emitsInOrder([
          isA<ProfileLoading>(),
          isA<ProfileError>(),
        ]),
      );

      await profileCubit.fetchProfile();
    });

    test('updateCustomerProfile emits [ProfileUpdating, ProfileLoaded] on successful update', () async {
      // Setup initial state as loaded first
      profileCubit.emit(const ProfileLoaded(user: testCustomer, orders: [], bookings: []));

      when(() => mockProfileRepository.updateCustomerProfile(
            fullName: any(named: 'fullName'),
            phone: any(named: 'phone'),
            savedAddresses: any(named: 'savedAddresses'),
          )).thenAnswer((_) async => testCustomer);

      expectLater(
        profileCubit.stream,
        emitsInOrder([
          isA<ProfileUpdating>(),
          isA<ProfileLoaded>(),
        ]),
      );

      await profileCubit.updateCustomerProfile(
        fullName: 'Erik New',
        phone: '0900123456',
        savedAddresses: {},
      );
    });

    test('updateDriverProfile preserves driverStats in emitted state', () async {
      final initialStats = {
        'totalRides': 10,
        'totalEarnings': 500.0,
        'averageRating': 4.5,
      };

      profileCubit.emit(ProfileLoaded(
        user: testDriver,
        orders: const [],
        bookings: const [],
        driverRecord: const {'id': 'driver-1', 'is_online': false},
        driverStats: initialStats,
      ));

      when(() => mockProfileRepository.updateDriverProfile(
            vehicleType: any(named: 'vehicleType'),
            vehiclePlate: any(named: 'vehiclePlate'),
            serviceClasses: any(named: 'serviceClasses'),
            isOnline: any(named: 'isOnline'),
          )).thenAnswer((_) async {});

      when(() => mockProfileRepository.getDriverRecord(any())).thenAnswer((_) async => {
        'id': 'driver-1',
        'is_online': true,
      });

      expectLater(
        profileCubit.stream,
        emitsInOrder([
          isA<ProfileUpdating>(),
          predicate<ProfileState>((state) {
            if (state is! ProfileLoaded) return false;
            expect(state.driverStats, initialStats);
            return true;
          }),
        ]),
      );

      await profileCubit.updateDriverProfile(
        vehicleType: 'Škoda Fabia',
        vehiclePlate: 'KE-999ZZ',
        serviceClasses: ['standard', 'comfort'],
        isOnline: true,
      );
    });

    test('registerAsDriver emits [ProfileUpdating, ProfileLoaded] and calls registerAsDriver', () async {
      profileCubit.emit(const ProfileLoaded(user: testCustomer, orders: [], bookings: []));

      when(() => mockProfileRepository.registerAsDriver(
            vehicleType: any(named: 'vehicleType'),
            vehiclePlate: any(named: 'vehiclePlate'),
            serviceClasses: any(named: 'serviceClasses'),
          )).thenAnswer((_) async => {});

      when(() => mockProfileRepository.getUserProfile()).thenAnswer((_) async => testCustomer);
      when(() => mockProfileRepository.getOrderHistory(any())).thenAnswer((_) async => []);
      when(() => mockProfileRepository.getBookingHistory(any())).thenAnswer((_) async => []);

      expectLater(
        profileCubit.stream,
        emitsInOrder([
          isA<ProfileUpdating>(),
          isA<ProfileLoading>(),
          isA<ProfileLoaded>(),
        ]),
      );

      await profileCubit.registerAsDriver(
        vehicleType: 'Škoda Superb',
        vehiclePlate: 'KE-555XX',
        serviceClasses: ['standard', 'premium'],
      );

      verify(() => mockProfileRepository.registerAsDriver(
            vehicleType: 'Škoda Superb',
            vehiclePlate: 'KE-555XX',
            serviceClasses: ['standard', 'premium'],
          )).called(1);
    });

    test('uploadDriverDocuments uploads 3 docs and saves references', () async {
      profileCubit.emit(const ProfileLoaded(user: testDriver, orders: [], bookings: []));

      when(() => mockProfileRepository.uploadDocument(
            documentType: any(named: 'documentType'),
            bytes: any(named: 'bytes'),
            fileName: any(named: 'fileName'),
          )).thenAnswer((invocation) async {
        final docType = invocation.namedArguments[#documentType] as String;
        return 'https://supabase.storage/driver-documents/$docType.jpg';
      });

      when(() => mockProfileRepository.saveDriverDocuments(
            profilePhotoUrl: any(named: 'profilePhotoUrl'),
            idCardUrl: any(named: 'idCardUrl'),
            licenseUrl: any(named: 'licenseUrl'),
          )).thenAnswer((_) async => {});

      when(() => mockProfileRepository.getUserProfile()).thenAnswer((_) async => testDriver);
      when(() => mockProfileRepository.getOrderHistory(any())).thenAnswer((_) async => []);
      when(() => mockProfileRepository.getBookingHistory(any())).thenAnswer((_) async => []);
      when(() => mockProfileRepository.getDriverRecord(any())).thenAnswer((_) async => {'id': 'driver_test'});
      when(() => mockProfileRepository.getDriverStats(any())).thenAnswer((_) async => {});
      when(() => mockProfileRepository.getDriverDocuments(any())).thenAnswer((_) async => {});

      expectLater(
        profileCubit.stream,
        emitsInOrder([
          isA<ProfileUpdating>(),
          isA<ProfileLoading>(),
          isA<ProfileLoaded>(),
        ]),
      );

      await profileCubit.uploadDriverDocuments(
        profilePhotoBytes: [1, 2, 3],
        profilePhotoName: 'photo.jpg',
        idCardBytes: [4, 5, 6],
        idCardName: 'id.jpg',
        licenseBytes: [7, 8, 9],
        licenseName: 'license.jpg',
      );

      verify(() => mockProfileRepository.uploadDocument(
            documentType: 'profile_photo',
            bytes: [1, 2, 3],
            fileName: 'photo.jpg',
          )).called(1);
      verify(() => mockProfileRepository.uploadDocument(
            documentType: 'id_card',
            bytes: [4, 5, 6],
            fileName: 'id.jpg',
          )).called(1);
      verify(() => mockProfileRepository.uploadDocument(
            documentType: 'license',
            bytes: [7, 8, 9],
            fileName: 'license.jpg',
          )).called(1);
      verify(() => mockProfileRepository.saveDriverDocuments(
            profilePhotoUrl: 'https://supabase.storage/driver-documents/profile_photo.jpg',
            idCardUrl: 'https://supabase.storage/driver-documents/id_card.jpg',
            licenseUrl: 'https://supabase.storage/driver-documents/license.jpg',
          )).called(1);
    });

    test('sendPhoneOtp calls sendPhoneOtp on repository', () async {
      when(() => mockProfileRepository.sendPhoneOtp(any())).thenAnswer((_) async => {});

      await profileCubit.sendPhoneOtp('+421900123456');

      verify(() => mockProfileRepository.sendPhoneOtp('+421900123456')).called(1);
    });

    test('verifyPhoneOtp returns true on success and false on failure', () async {
      when(() => mockProfileRepository.verifyPhoneOtp('+421900123456', '123456')).thenAnswer((_) async => true);
      when(() => mockProfileRepository.verifyPhoneOtp('+421900123456', '000000')).thenAnswer((_) async => false);

      final success = await profileCubit.verifyPhoneOtp('+421900123456', '123456');
      final failure = await profileCubit.verifyPhoneOtp('+421900123456', '000000');

      expect(success, isTrue);
      expect(failure, isFalse);
    });

    test('applyReferralCode calls applyReferralCode and fetches profile on success', () async {
      profileCubit.emit(const ProfileLoaded(user: testCustomer, orders: [], bookings: []));

      when(() => mockProfileRepository.applyReferralCode('MICHAL80')).thenAnswer((_) async => {});
      when(() => mockProfileRepository.getUserProfile()).thenAnswer((_) async => testCustomer);
      when(() => mockProfileRepository.getOrderHistory(any())).thenAnswer((_) async => []);
      when(() => mockProfileRepository.getBookingHistory(any())).thenAnswer((_) async => []);

      final result = await profileCubit.applyReferralCode('MICHAL80');

      expect(result, isNull);
      verify(() => mockProfileRepository.applyReferralCode('MICHAL80')).called(1);
      verify(() => mockProfileRepository.getUserProfile()).called(1);
    });

    test('applyReferralCode returns error message on exception', () async {
      profileCubit.emit(const ProfileLoaded(user: testCustomer, orders: [], bookings: []));

      when(() => mockProfileRepository.applyReferralCode('INVALID')).thenThrow(Exception('Neplatný referenčný kód.'));

      final result = await profileCubit.applyReferralCode('INVALID');

      expect(result, 'Neplatný referenčný kód.');
      verify(() => mockProfileRepository.applyReferralCode('INVALID')).called(1);
    });
  });
}
