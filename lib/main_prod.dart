import 'core/config/app_config.dart';
import 'main_common.dart';

void main() {
  const mockMode = bool.fromEnvironment('MOCK_MODE', defaultValue: false) ||
      String.fromEnvironment('BACKEND_MODE') == 'mock';
  assert(!mockMode, 'MOCK_MODE must be false in production builds.');
  if (mockMode) {
    throw StateError('Security violation: MOCK_MODE environment variable cannot be true in production.');
  }

  final prodConfig = AppConfig(
    environment: AppEnvironment.prod,
    supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    stripePublishableKey: const String.fromEnvironment('STRIPE_KEY_PROD'),
    enableMockMode: false,
    enableAnalytics: true,
  );

  mainCommon(prodConfig);
}
