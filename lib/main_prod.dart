import 'core/config/app_config.dart';
import 'main_common.dart';

void main() {
  final prodConfig = AppConfig(
    environment: AppEnvironment.prod,
    supabaseUrl: const String.fromEnvironment(
      'SUPABASE_URL_PROD',
      defaultValue: 'https://gold-taxi.supabase.co',
    ),
    supabaseAnonKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY_PROD',
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
