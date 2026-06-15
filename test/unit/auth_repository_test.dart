import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gold_taxi/features/auth/data/repositories/auth_repository.dart';
import 'package:gold_taxi/core/services/local_storage_service.dart';

class MockLocalStorageService extends Mock implements LocalStorageService {}
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}
class MockPostgrestFilterBuilder extends Mock implements PostgrestFilterBuilder<PostgrestList> {}
class MockPostgrestTransformBuilder extends Mock implements PostgrestTransformBuilder<PostgrestMap> {}
class MockAuthResponse extends Mock implements AuthResponse {}
class MockUser extends Mock implements User {}
class MockSession extends Mock implements Session {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AuthRepository authRepository;
  late MockLocalStorageService mockStorageService;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;

  setUp(() {
    mockStorageService = MockLocalStorageService();
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();

    when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);

    authRepository = AuthRepository(
      mockStorageService,
      supabaseClient: mockSupabaseClient,
    );
  });

  group('AuthRepository Supabase Unit Tests', () {
    test('login returns true on successful Supabase authentication', () async {
      final mockResponse = MockAuthResponse();
      final mockUser = MockUser();

      when(() => mockGoTrueClient.signInWithPassword(
        email: 'test@example.com',
        password: 'password123',
      )).thenAnswer((_) async => mockResponse);
      when(() => mockResponse.user).thenReturn(mockUser);

      final result = await authRepository.login('test@example.com', 'password123');

      expect(result, isTrue);
      verify(() => mockGoTrueClient.signInWithPassword(
        email: 'test@example.com',
        password: 'password123',
      )).called(1);
    });

    test('login propagates error on Supabase exception and does not fallback to mock', () async {
      when(() => mockGoTrueClient.signInWithPassword(
        email: 'test@example.com',
        password: 'wrongpassword',
      )).thenThrow(const AuthException('Invalid login credentials'));

      expect(
        () => authRepository.login('test@example.com', 'wrongpassword'),
        throwsA(isA<AuthException>()),
      );
    });

    test('logout clears local token and signs out of Supabase', () async {
      when(() => mockStorageService.deleteToken()).thenAnswer((_) async {});
      when(() => mockGoTrueClient.signOut()).thenAnswer((_) async {});

      await authRepository.logout();

      verify(() => mockStorageService.deleteToken()).called(1);
      verify(() => mockGoTrueClient.signOut()).called(1);
    });

    test('isAuthenticated returns true when session is active', () async {
      final mockSession = MockSession();
      when(() => mockGoTrueClient.currentSession).thenReturn(mockSession);

      final result = await authRepository.isAuthenticated();

      expect(result, isTrue);
    });

    test('isAuthenticated returns false when session is null', () async {
      when(() => mockGoTrueClient.currentSession).thenReturn(null);

      final result = await authRepository.isAuthenticated();

      expect(result, isFalse);
    });

    test('getCurrentUser loads profile from Supabase profiles table', () async {
      final mockUser = MockUser();
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder = MockPostgrestFilterBuilder();
      final mockTransformBuilder = MockPostgrestTransformBuilder();

      when(() => mockUser.id).thenReturn('user-uuid-123');
      when(() => mockGoTrueClient.currentUser).thenReturn(mockUser);
      when(() => mockSupabaseClient.from('profiles')).thenReturn(mockQueryBuilder);
      when(() => mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.eq('id', 'user-uuid-123')).thenReturn(mockTransformBuilder);
      when(() => mockTransformBuilder.single()).thenAnswer((_) async => {
        'id': 'user-uuid-123',
        'email': 'test@example.com',
        'full_name': 'Test User',
        'role': 'driver',
      });

      final result = await authRepository.getCurrentUser();

      expect(result, isNotNull);
      expect(result?.id, 'user-uuid-123');
      expect(result?.email, 'test@example.com');
      expect(result?.name, 'Test User');
      expect(result?.role, 'driver');
      expect(result?.isDriver, isTrue);
    });
  });
}

