import 'core/config/app_config.dart';
import 'main_common.dart';

void main() {
  final devConfig = AppConfig(
    environment: AppEnvironment.dev,
    supabaseUrl: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://dev-supabase.supabase.co',
    ),
    supabaseAnonKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'dev-supabase-anon-key',
    ),
    stripePublishableKey: const String.fromEnvironment(
      'STRIPE_KEY_DEV',
      defaultValue: 'pk_test_dev_stripe_key',
    ),
    enableMockMode:
        const String.fromEnvironment('BACKEND_MODE') == 'mock' ||
        const bool.fromEnvironment('MOCK_MODE', defaultValue: false),
    enableAnalytics: false,
  );

  mainCommon(devConfig);
}
