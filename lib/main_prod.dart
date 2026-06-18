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
    supabaseUrl: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://nscxuxhapaabtsiduxlu.supabase.co',
    ),
    supabaseAnonKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5zY3h1eGhhcGFhYnRzaWR1eGx1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEzODEwNzAsImV4cCI6MjA5Njk1NzA3MH0.AI-8BfolBjcxMRDS5YlDCFSK5CrQyFck5Mf3TVIErO0',
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
