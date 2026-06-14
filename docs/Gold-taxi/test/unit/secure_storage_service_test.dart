import 'package:flutter_test/flutter_test.dart';
import 'package:gold_taxi/core/services/secure_storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late SecureStorageService secureStorageService;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    secureStorageService = SecureStorageService(storage: mockStorage);
  });

  group('SecureStorageService Unit Tests', () {
    test('1. Initialized service has correct type', () {
      expect(secureStorageService, isA<SecureStorageService>());
    });

    test('2. getToken initially returns null or handles missing token gracefully', () async {
      when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
      final result = await secureStorageService.getToken();
      expect(result, null);
    });

    test('3. saveToken does not throw exceptions', () async {
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async => {});
      await expectLater(secureStorageService.saveToken('test_token'), completes);
    });

    test('4. deleteToken does not throw exceptions', () async {
      when(() => mockStorage.delete(key: any(named: 'key'))).thenAnswer((_) async => {});
      await expectLater(secureStorageService.deleteToken(), completes);
    });
  });
}
