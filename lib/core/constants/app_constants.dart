/// Application Constants
class AppConstants {
  // App Info
  static const String appName = 'Gold-Taxi';
  static const String appVersion = '1.0.0';
  static const String appPackage = 'com.goldtaxi.gold_taxi';
  static const String appDescription =
      'Gold-Taxi - WordPress JetEngine Mobile App';

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration cacheExpiration = Duration(hours: 24);

  // Pagination
  static const int defaultPageSize = 10;
  static const int maxPageSize = 100;

  // String limits
  static const int maxPasswordLength = 128;
  static const int minPasswordLength = 6;
  static const int maxEmailLength = 254;

  // Cache keys
  static const String tokenCacheKey = 'auth_token';
  static const String userCacheKey = 'current_user';
  static const String refreshTokenCacheKey = 'refresh_token';
  static const String userPreferencesCacheKey = 'user_preferences';
  static const String postsCacheKey = 'posts_cache';
  static const String productsCacheKey = 'products_cache';
  static const String servicesCacheKey = 'services_cache';
  static const String eventsCacheKey = 'events_cache';
}

/// Feature flags
class FeatureFlags {
  static const bool enableOfflineSync = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enableDeepLinking = true;
  static const bool enableNotifications = true;
  static const bool enableFollowSystem = true;
}
