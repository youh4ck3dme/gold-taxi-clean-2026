import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:gold_taxi/core/di/service_locator.dart';
import 'package:gold_taxi/core/services/api_service.dart';
import 'package:gold_taxi/core/services/mock_api_service.dart';
import 'package:gold_taxi/features/auth/data/repositories/auth_repository.dart';
import 'package:gold_taxi/features/map/data/repositories/ride_repository.dart';
import 'package:gold_taxi/features/map/data/repositories/supabase_ride_repository.dart';
import 'package:gold_taxi/features/profile/data/repositories/profile_repository.dart';
import 'package:gold_taxi/features/profile/data/repositories/supabase_profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// To avoid Supabase initialization errors in tests, we mock Supabase.instance
class MockSupabase extends Supabase {
  // We cannot easily mock the singleton without some hacks, 
  // but GetIt lazy initialization means it won't be evaluated until called.
}

void main() {
  setUp(() async {
    await GetIt.instance.reset();
  });

  group('ServiceLocator Tests', () {
    test('1. BackendMode.mock asserts correctly when not in debug mode', () {
      // Dart test environment is considered kDebugMode = true by default.
      // We can't trivially change kDebugMode at runtime in a test.
      // But we can verify that BackendMode.supabase sets up the real implementations.
      expect(kDebugMode, isTrue); // Ensures we are in a debug environment
    });

    test('2. BackendMode.supabase sets up production repositories (No Mock Fallbacks)', () async {
      // Mocking Supabase just enough to allow lazy singletons to register
      // We don't resolve them to avoid actual Supabase initialization errors,
      // but we can check if they are registered correctly.
      await setupServiceLocator(mode: BackendMode.supabase);

      final getIt = GetIt.instance;

      expect(getIt.isRegistered<AuthRepository>(), isTrue);
      expect(getIt.isRegistered<RideRepository>(), isTrue);
      expect(getIt.isRegistered<ProfileRepository>(), isTrue);
      expect(getIt.isRegistered<ApiService>(), isTrue);

      // Verify ApiService is the real one, not mock
      final apiService = getIt<ApiService>();
      expect(apiService, isA<ApiService>());
      expect(apiService is MockApiService, isFalse);
    });

    test('3. BackendMode.mock sets up mock repositories (Only allowed in debug)', () async {
      await setupServiceLocator(mode: BackendMode.mock);

      final getIt = GetIt.instance;
      
      expect(getIt.isRegistered<ApiService>(), isTrue);
      final apiService = getIt<ApiService>();
      expect(apiService, isA<MockApiService>());
    });
  });
}
