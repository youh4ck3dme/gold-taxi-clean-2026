

/// API Constants for WordPress JetEngine integration
class ApiConstants {
  static String get baseUrl => const String.fromEnvironment('WP_BASE_URL', defaultValue: 'https://your-wordpress-site.com');

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


  // Firebase
  static String get firebaseProjectId => const String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'your-firebase-project-id');
  static String get firebaseApiKey => const String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'your-firebase-api-key');
  static String get firebaseAppId => const String.fromEnvironment('FIREBASE_APP_ID', defaultValue: 'your-firebase-app-id');

  // WooCommerce
  static String get wooCommerceConsumerKey => const String.fromEnvironment('WOO_CONSUMER_KEY', defaultValue: '');
  static String get wooCommerceConsumerSecret => const String.fromEnvironment('WOO_CONSUMER_SECRET', defaultValue: '');
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
