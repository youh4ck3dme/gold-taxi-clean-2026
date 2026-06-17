import 'core/config/app_config.dart';
import 'main_common.dart';

void main() {
  final mockConfig = AppConfig(
    environment: AppEnvironment.dev,
    supabaseUrl: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://test.supabase.co',
    ),
    supabaseAnonKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'test-anon-key',
    ),
    stripePublishableKey: const String.fromEnvironment(
      'STRIPE_KEY_DEV',
      defaultValue: 'pk_test_dev_stripe_key',
    ),
    enableMockMode: true,
    enableAnalytics: false,
  );

  mainCommon(mockConfig);
}
