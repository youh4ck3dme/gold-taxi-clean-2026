enum AppEnvironment { dev, prod }

class AppConfig {
  final AppEnvironment environment;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String stripePublishableKey;
  final bool enableMockMode;
  final bool enableAnalytics;

  AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.stripePublishableKey,
    required this.enableMockMode,
    required this.enableAnalytics,
  });

  bool get isDev => environment == AppEnvironment.dev;
  bool get isProd => environment == AppEnvironment.prod;
}
