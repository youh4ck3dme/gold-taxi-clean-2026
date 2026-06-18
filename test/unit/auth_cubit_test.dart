import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gold_taxi/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:gold_taxi/features/auth/presentation/cubits/auth_state.dart';
import 'package:gold_taxi/features/auth/data/repositories/auth_repository.dart';
import 'package:gold_taxi/models/user_model.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AuthCubit authCubit;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authCubit = AuthCubit(mockAuthRepository);
  });

  tearDown(() async {
    await authCubit.close();
  });

  group('AuthCubit Unit Tests', () {
    const testUser = UserModel(
      id: '1',
      name: 'Test User',
      email: 'test@test.com',
      role: UserRole.subscriber,
    );

    test('1. Initial state is AuthInitial', () {
      expect(authCubit.state, isA<AuthInitial>());
    });

    test(
      '2. checkAuthStatus emits [AuthLoading, Authenticated] when token exists and user is loaded',
      () async {
        when(
          () => mockAuthRepository.isAuthenticated(),
        ).thenAnswer((_) async => true);
        when(
          () => mockAuthRepository.getCurrentUser(),
        ).thenAnswer((_) async => testUser);

        expectLater(
          authCubit.stream,
          emitsInOrder([isA<AuthLoading>(), isA<Authenticated>()]),
        );

        await authCubit.checkAuthStatus();
      },
    );

    test(
      '3. checkAuthStatus emits [AuthLoading, Unauthenticated] when token is missing',
      () async {
        when(
          () => mockAuthRepository.isAuthenticated(),
        ).thenAnswer((_) async => false);

        expectLater(
          authCubit.stream,
          emitsInOrder([isA<AuthLoading>(), isA<Unauthenticated>()]),
        );

        await authCubit.checkAuthStatus();
      },
    );

    test(
      '4. checkAuthStatus emits [AuthLoading, AuthError] when token exists but user fails',
      () async {
        when(
          () => mockAuthRepository.isAuthenticated(),
        ).thenAnswer((_) async => true);
        when(
          () => mockAuthRepository.getCurrentUser(),
        ).thenAnswer((_) async => null);

        expectLater(
          authCubit.stream,
          emitsInOrder([isA<AuthLoading>(), isA<AuthError>()]),
        );

        await authCubit.checkAuthStatus();
      },
    );

    test('5. login emits [AuthLoading, Authenticated] on success', () async {
      when(
        () => mockAuthRepository.login('user', 'pass'),
      ).thenAnswer((_) async => true);
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => testUser);

      expectLater(
        authCubit.stream,
        emitsInOrder([isA<AuthLoading>(), isA<Authenticated>()]),
      );

      await authCubit.login('user', 'pass');
    });

    test(
      '6. login emits [AuthLoading, AuthError, Unauthenticated] on failure',
      () async {
        when(
          () => mockAuthRepository.login('user', 'wrong'),
        ).thenAnswer((_) async => false);

        expectLater(
          authCubit.stream,
          emitsInOrder([
            isA<AuthLoading>(),
            isA<AuthError>(),
            isA<Unauthenticated>(),
          ]),
        );

        await authCubit.login('user', 'wrong');
      },
    );

    test(
      '7. login emits [AuthLoading, AuthError, Unauthenticated] when AuthException is thrown',
      () async {
        when(
          () => mockAuthRepository.login('user', 'wrong'),
        ).thenThrow(const AuthException('Invalid login credentials'));

        expectLater(
          authCubit.stream,
          emitsInOrder([
            isA<AuthLoading>(),
            isA<AuthError>(),
            isA<Unauthenticated>(),
          ]),
        );

        await authCubit.login('user', 'wrong');
      },
    );

    test('8. logout emits [AuthLoading, Unauthenticated]', () async {
      when(() => mockAuthRepository.logout()).thenAnswer((_) async {});

      expectLater(
        authCubit.stream,
        emitsInOrder([isA<AuthLoading>(), isA<Unauthenticated>()]),
      );

      await authCubit.logout();
    });

    test(
      '9. signInWithGoogle emits [AuthLoading, Authenticated] on success',
      () async {
        when(
          () => mockAuthRepository.signInWithGoogle(),
        ).thenAnswer((_) async => testUser);

        expectLater(
          authCubit.stream,
          emitsInOrder([isA<AuthLoading>(), isA<Authenticated>()]),
        );

        await authCubit.signInWithGoogle();
      },
    );

    test(
      '10. signInWithGoogle emits [AuthLoading, AuthError] on null user',
      () async {
        when(
          () => mockAuthRepository.signInWithGoogle(),
        ).thenAnswer((_) async => null);

        expectLater(
          authCubit.stream,
          emitsInOrder([isA<AuthLoading>(), isA<AuthError>()]),
        );

        await authCubit.signInWithGoogle();
      },
    );

    test(
      '11. signInWithGoogle emits [AuthLoading, AuthError, Unauthenticated] on AuthException',
      () async {
        when(
          () => mockAuthRepository.signInWithGoogle(),
        ).thenThrow(const AuthException('Google Auth cancelled'));

        expectLater(
          authCubit.stream,
          emitsInOrder([
            isA<AuthLoading>(),
            isA<AuthError>(),
            isA<Unauthenticated>(),
          ]),
        );

        await authCubit.signInWithGoogle();
      },
    );
  });
}
