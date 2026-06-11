import 'package:flutter_test/flutter_test.dart';
import 'package:gold_taxi/auth/bloc/auth_bloc.dart';
import 'package:gold_taxi/auth/bloc/auth_event.dart';
import 'package:gold_taxi/auth/bloc/auth_state.dart';
import 'package:gold_taxi/auth/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  UserProfile? currentUserResult;
  UserProfile? loginResult;
  UserProfile? registerResult;
  bool logoutCalled = false;
  Object? errorToThrow;
  Object? loginErrorToThrow;
  Object? registerErrorToThrow;
  Object? logoutErrorToThrow;

  @override
  Future<UserProfile?> getCurrentUser() async {
    if (errorToThrow != null) throw errorToThrow!;
    return currentUserResult;
  }

  @override
  Future<UserProfile?> login(String email, String password) async {
    if (loginErrorToThrow != null) throw loginErrorToThrow!;
    return loginResult;
  }

  @override
  Future<UserProfile?> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    if (registerErrorToThrow != null) throw registerErrorToThrow!;
    return registerResult;
  }

  @override
  Future<void> logout() async {
    if (logoutErrorToThrow != null) throw logoutErrorToThrow!;
    logoutCalled = true;
  }
}

void main() {
  late FakeAuthRepository fakeAuthRepository;
  late AuthBloc authBloc;

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
    authBloc = AuthBloc(authRepository: fakeAuthRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc Tests', () {
    test('AppStarted: Úspešné načítanie používateľa', () async {
      final mockProfile = UserProfile(
        id: 'user-id',
        email: 'test@example.com',
        role: 'customer',
        fullName: 'Test User',
      );
      fakeAuthRepository.currentUserResult = mockProfile;

      authBloc.add(AppStarted());

      await expectLater(
        authBloc.stream,
        emitsInOrder([
          AuthLoading(),
          Authenticated(mockProfile),
        ]),
      );
    });

    test('AppStarted: Žiadny prihlásený používateľ', () async {
      fakeAuthRepository.currentUserResult = null;

      authBloc.add(AppStarted());

      await expectLater(
        authBloc.stream,
        emitsInOrder([
          AuthLoading(),
          Unauthenticated(),
        ]),
      );
    });

    test('LoginRequested: Úspešné prihlásenie', () async {
      final mockProfile = UserProfile(
        id: 'user-id',
        email: 'test@example.com',
        role: 'driver',
        fullName: 'Test Driver',
      );
      fakeAuthRepository.loginResult = mockProfile;

      authBloc.add(const LoginRequested('test@example.com', 'password123'));

      await expectLater(
        authBloc.stream,
        emitsInOrder([
          AuthLoading(),
          Authenticated(mockProfile),
        ]),
      );
    });

    test('LoginRequested: Zlyhanie (chyba)', () async {
      fakeAuthRepository.loginErrorToThrow = Exception('Chybné heslo');

      authBloc.add(const LoginRequested('test@example.com', 'wrongpassword'));

      await expectLater(
        authBloc.stream,
        emitsInOrder([
          AuthLoading(),
          const AuthError('Exception: Chybné heslo'),
          Unauthenticated(),
        ]),
      );
    });

    test('RegisterRequested: Úspešná registrácia', () async {
      final mockProfile = UserProfile(
        id: 'new-user-id',
        email: 'new@example.com',
        role: 'customer',
        fullName: 'New User',
      );
      fakeAuthRepository.registerResult = mockProfile;

      authBloc.add(const RegisterRequested(
        email: 'new@example.com',
        password: 'password123',
        fullName: 'New User',
        role: 'customer',
      ));

      await expectLater(
        authBloc.stream,
        emitsInOrder([
          AuthLoading(),
          Authenticated(mockProfile),
        ]),
      );
    });

    test('LogoutRequested: Úspešné odhlásenie', () async {
      authBloc.add(LogoutRequested());

      await expectLater(
        authBloc.stream,
        emitsInOrder([
          AuthLoading(),
          Unauthenticated(),
        ]),
      );
      expect(fakeAuthRepository.logoutCalled, isTrue);
    });
  });
}
