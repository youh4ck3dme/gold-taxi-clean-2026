import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gold_taxi/core/services/local_storage_service.dart';
import 'package:gold_taxi/features/auth/data/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockLocalStorageService extends Mock implements LocalStorageService {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockAuthResponse extends Mock implements AuthResponse {}

class MockSession extends Mock implements Session {}

class MockUser extends Mock implements User {}

void main() {
  late AuthRepository authRepository;
  late MockLocalStorageService mockStorageService;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockAuth;

  setUpAll(() {
    registerFallbackValue(OAuthProvider.google);
  });

  setUp(() {
    mockStorageService = MockLocalStorageService();
    mockSupabaseClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();

    when(() => mockSupabaseClient.auth).thenReturn(mockAuth);

    authRepository = SupabaseAuthRepository(
      mockSupabaseClient,
      mockStorageService,
    );
  });

  group('AuthRepository Unit Tests', () {
    test('login returns true and saves token on successful API call', () async {
      final mockResponse = MockAuthResponse();
      final mockSession = MockSession();

      when(() => mockResponse.session).thenReturn(mockSession);
      when(() => mockSession.accessToken).thenReturn('mock_supabase_token');

      when(
        () => mockAuth.signInWithPassword(
          email: 'testuser@test.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => mockResponse);

      when(
        () => mockStorageService.saveToken('mock_supabase_token'),
      ).thenAnswer((_) async {});

      final result = await authRepository.login(
        'testuser@test.com',
        'password123',
      );

      expect(result, isTrue);
      verify(
        () => mockStorageService.saveToken('mock_supabase_token'),
      ).called(1);
    });

    test('login returns false when API throws error', () async {
      when(
        () => mockAuth.signInWithPassword(
          email: 'wronguser@test.com',
          password: 'wrongpassword',
        ),
      ).thenThrow(const AuthException('Invalid credentials'));

      final result = await authRepository.login(
        'wronguser@test.com',
        'wrongpassword',
      );

      expect(result, isFalse);
      verifyNever(() => mockStorageService.saveToken(any()));
    });

    test('logout deletes stored token and signs out of Supabase', () async {
      when(() => mockStorageService.deleteToken()).thenAnswer((_) async {});
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      await authRepository.logout();

      verify(() => mockStorageService.deleteToken()).called(1);
      verify(() => mockAuth.signOut()).called(1);
    });

    test('isAuthenticated returns true when session exists', () async {
      final mockSession = MockSession();
      when(() => mockAuth.currentSession).thenReturn(mockSession);

      final result = await authRepository.isAuthenticated();

      expect(result, isTrue);
    });

    test('isAuthenticated returns false when session does not exist', () async {
      when(() => mockAuth.currentSession).thenReturn(null);

      final result = await authRepository.isAuthenticated();

      expect(result, isFalse);
    });
  });
}
