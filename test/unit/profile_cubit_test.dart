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
    const testUser = UserModel(
      id: '1',
      name: 'Driver Erik',
      email: 'erik@goldtaxi.com',
      role: 'driver',
    );

    test('Initial state is ProfileInitial', () {
      expect(profileCubit.state, isA<ProfileInitial>());
    });

    test('fetchProfile emits [ProfileLoading, ProfileLoaded] when repository succeeds', () async {
      when(() => mockProfileRepository.getUserProfile()).thenAnswer((_) async => testUser);
      when(() => mockProfileRepository.getOrderHistory(any())).thenAnswer((_) async => []);
      when(() => mockProfileRepository.getBookingHistory(any())).thenAnswer((_) async => []);
      when(() => mockProfileRepository.getDriverRecord(any())).thenAnswer((_) async => {'is_online': true});

      expectLater(
        profileCubit.stream,
        emitsInOrder([
          isA<ProfileLoading>(),
          isA<ProfileLoaded>(),
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
      profileCubit.emit(const ProfileLoaded(user: testUser, orders: [], bookings: []));

      when(() => mockProfileRepository.updateCustomerProfile(
            fullName: any(named: 'fullName'),
            phone: any(named: 'phone'),
            savedAddresses: any(named: 'savedAddresses'),
          )).thenAnswer((_) async => testUser);

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
  });
}
