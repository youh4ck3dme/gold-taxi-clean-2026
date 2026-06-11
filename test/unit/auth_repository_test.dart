import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gold_taxi/core/services/api_service.dart';
import 'package:gold_taxi/core/services/local_storage_service.dart';
import 'package:gold_taxi/features/auth/data/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';

class MockApiService extends Mock implements ApiService {}
class MockLocalStorageService extends Mock implements LocalStorageService {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AuthRepository authRepository;
  late MockApiService mockApiService;
  late MockLocalStorageService mockStorageService;
  late MockFirebaseAuth mockFirebaseAuth;

  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  setUp(() {
    mockApiService = MockApiService();
    mockStorageService = MockLocalStorageService();
    mockFirebaseAuth = MockFirebaseAuth();
    authRepository = AuthRepository(
      mockApiService,
      mockStorageService,
      firebaseAuth: mockFirebaseAuth,
    );
  });

  group('AuthRepository Unit Tests', () {
    test('login returns true and saves token on successful API call', () async {
      when(() => mockApiService.post(
            '/wp-json/jwt-auth/v1/token',
            data: {'username': 'testuser', 'password': 'password123'},
          )).thenAnswer((_) async => {'token': 'jwt_mock_token'});

      when(() => mockStorageService.saveToken('jwt_mock_token')).thenAnswer((_) async {});

      final result = await authRepository.login('testuser', 'password123');

      expect(result, isTrue);
      verify(() => mockStorageService.saveToken('jwt_mock_token')).called(1);
    });

    test('login returns false when API throws error', () async {
      when(() => mockApiService.post(
            '/wp-json/jwt-auth/v1/token',
            data: {'username': 'wronguser', 'password': 'wrongpassword'},
          )).thenThrow(Exception('Unauthorized'));

      final result = await authRepository.login('wronguser', 'wrongpassword');

      expect(result, isFalse);
      verifyNever(() => mockStorageService.saveToken(any()));
    });

    test('logout deletes stored token', () async {
      when(() => mockStorageService.deleteToken()).thenAnswer((_) async {});

      await authRepository.logout();

      verify(() => mockStorageService.deleteToken()).called(1);
    });

    test('isAuthenticated returns true when token exists', () async {
      when(() => mockStorageService.getToken()).thenAnswer((_) async => 'some_token');

      final result = await authRepository.isAuthenticated();

      expect(result, isTrue);
    });

    test('isAuthenticated returns false when token does not exist', () async {
      when(() => mockStorageService.getToken()).thenAnswer((_) async => null);

      final result = await authRepository.isAuthenticated();

      expect(result, isFalse);
    });
  });
}
