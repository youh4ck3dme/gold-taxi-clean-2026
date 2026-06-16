import 'core/config/app_config.dart';
import 'main_common.dart';

void main() {
  const mockMode = bool.fromEnvironment('MOCK_MODE', defaultValue: false);
  assert(!mockMode, 'MOCK_MODE must be false in production builds.');
  if (mockMode) {
    throw StateError('Security violation: MOCK_MODE environment variable cannot be true in production.');
  }

  final prodConfig = AppConfig(
    environment: AppEnvironment.prod,
    supabaseUrl: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://gold-taxi.supabase.co',
    ),
    supabaseAnonKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'prod-supabase-anon-key',
    ),
    stripePublishableKey: const String.fromEnvironment(
      'STRIPE_KEY_PROD',
      defaultValue: 'pk_live_prod_stripe_key',
    ),
    enableMockMode: false,
    enableAnalytics: true,
  );

  mainCommon(prodConfig);
}
