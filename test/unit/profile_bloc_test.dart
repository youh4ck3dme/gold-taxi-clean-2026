import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gold_taxi/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:gold_taxi/features/profile/presentation/bloc/profile_event.dart';
import 'package:gold_taxi/features/profile/presentation/bloc/profile_state.dart';
import 'package:gold_taxi/features/profile/data/repositories/profile_repository.dart';
import 'package:gold_taxi/models/user_model.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late ProfileBloc profileBloc;
  late MockProfileRepository mockProfileRepository;

  setUp(() {
    mockProfileRepository = MockProfileRepository();
    profileBloc = ProfileBloc(mockProfileRepository);
  });

  tearDown(() {
    profileBloc.close();
  });

  group('ProfileBloc Tests', () {
    const testUser = UserModel(
      id: 1,
      name: 'Driver Erik',
      email: 'erik@goldtaxi.com',
      role: 'driver',
    );

    test('Initial state is ProfileInitial', () {
      expect(profileBloc.state, isA<ProfileInitial>());
    });

    test('FetchProfile emits [ProfileLoading, ProfileLoaded] when repository succeeds', () async {
      when(() => mockProfileRepository.getUserProfile()).thenAnswer((_) async => testUser);
      when(() => mockProfileRepository.getOrderHistory(any())).thenAnswer((_) async => []);
      when(() => mockProfileRepository.getBookingHistory(any())).thenAnswer((_) async => []);

      expectLater(
        profileBloc.stream,
        emitsInOrder([
          isA<ProfileLoading>(),
          isA<ProfileLoaded>(),
        ]),
      );

      profileBloc.add(FetchProfile());
    });

    test('FetchProfile emits [ProfileLoading, ProfileError] when repository fails', () async {
      when(() => mockProfileRepository.getUserProfile()).thenThrow(Exception('API error'));

      expectLater(
        profileBloc.stream,
        emitsInOrder([
          isA<ProfileLoading>(),
          isA<ProfileError>(),
        ]),
      );

      profileBloc.add(FetchProfile());
    });

    test('UpdateProfile emits [ProfileUpdating, ProfileLoaded] on successful update', () async {
      // Setup initial state as loaded first
      profileBloc.emit(const ProfileLoaded(user: testUser, orders: [], bookings: []));

      when(() => mockProfileRepository.updateUserProfile(
            name: any(named: 'name'),
            bio: any(named: 'bio'),
          )).thenAnswer((_) async => testUser);
      when(() => mockProfileRepository.getOrderHistory(any())).thenAnswer((_) async => []);
      when(() => mockProfileRepository.getBookingHistory(any())).thenAnswer((_) async => []);

      expectLater(
        profileBloc.stream,
        emitsInOrder([
          isA<ProfileUpdating>(),
          isA<ProfileLoaded>(),
        ]),
      );

      profileBloc.add(const UpdateProfile(name: 'Erik New', bio: 'Taxi driver'));
    });
  });
}
