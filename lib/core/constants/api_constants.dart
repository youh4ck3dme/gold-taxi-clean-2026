import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API Constants for WordPress JetEngine integration
class ApiConstants {
  static String get baseUrl => const String.fromEnvironment('WP_BASE_URL').isNotEmpty
      ? const String.fromEnvironment('WP_BASE_URL')
      : dotenv.env['WP_BASE_URL'] ?? 'https://your-wordpress-site.com';

  // WordPress API endpoints
  static String get wordpressApi => '$baseUrl/wp-json/wp/v2';
  static String get jetEngineApi => '$baseUrl/wp-json/jet-engine/v1';
  static String get wooCommerceApi => '$baseUrl/wp-json/wc/v3';

  // Endpoints
  static String get postsEndpoint => '$wordpressApi/posts';
  static String get productsEndpoint => '$wooCommerceApi/products';
  static String get servicesEndpoint => '$wordpressApi/posts'; // Fallback to standard WP posts
  static String get eventsEndpoint => '$wordpressApi/posts'; // Fallback to standard WP posts
  static String get usersEndpoint => '$wordpressApi/users';
  static String get categoriesEndpoint => '$wordpressApi/categories';
  static String get tagsEndpoint => '$wordpressApi/tags';
  static String get reviewsEndpoint => '$wordpressApi/posts'; // Graceful fallback
  static String get bookingsEndpoint => '$wordpressApi/posts'; // Graceful fallback
  static String get ordersEndpoint => '$wooCommerceApi/orders';
  static String get notificationsEndpoint => '$wordpressApi/posts'; // Graceful fallback
  static String get faqEndpoint => '$wordpressApi/posts'; // Graceful fallback

  // Auth endpoints
  static String get loginEndpoint => '$baseUrl/wp-json/jwt-auth/v1/token';
  static String get validateTokenEndpoint => '$baseUrl/wp-json/jwt-auth/v1/token/validate';
  static String get refreshTokenEndpoint => '$baseUrl/wp-json/jwt-auth/v1/token/refresh';

  // Firebase
  static String get firebaseProjectId => const String.fromEnvironment('FIREBASE_PROJECT_ID').isNotEmpty
      ? const String.fromEnvironment('FIREBASE_PROJECT_ID')
      : dotenv.env['FIREBASE_PROJECT_ID'] ?? 'your-firebase-project-id';
  static String get firebaseApiKey => const String.fromEnvironment('FIREBASE_API_KEY').isNotEmpty
      ? const String.fromEnvironment('FIREBASE_API_KEY')
      : dotenv.env['FIREBASE_API_KEY'] ?? 'your-firebase-api-key';
  static String get firebaseAppId => const String.fromEnvironment('FIREBASE_APP_ID').isNotEmpty
      ? const String.fromEnvironment('FIREBASE_APP_ID')
      : dotenv.env['FIREBASE_APP_ID'] ?? 'your-firebase-app-id';

  // WooCommerce
  static String get wooCommerceConsumerKey => const String.fromEnvironment('WOO_CONSUMER_KEY').isNotEmpty
      ? const String.fromEnvironment('WOO_CONSUMER_KEY')
      : dotenv.env['WOO_CONSUMER_KEY'] ?? '';
  static String get wooCommerceConsumerSecret => const String.fromEnvironment('WOO_CONSUMER_SECRET').isNotEmpty
      ? const String.fromEnvironment('WOO_CONSUMER_SECRET')
      : dotenv.env['WOO_CONSUMER_SECRET'] ?? '';
}

/// Query parameters
class QueryParams {
  static const String page = 'page';
  static const String perPage = 'per_page';
  static const String search = 'search';
  static const String category = 'category';
  static const String tags = 'tags';
  static const String author = 'author';
  static const String orderBy = 'orderby';
  static const String order = 'order';
  static const String embed = '_embed';
  static const String fields = '_fields';
}
