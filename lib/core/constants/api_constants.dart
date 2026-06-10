/// API Constants for WordPress JetEngine integration
class ApiConstants {
  static const String baseUrl = 'https://your-wordpress-site.com';

  // WordPress API endpoints
  static const String wordpressApi = '$baseUrl/wp-json/wp/v2';
  static const String jetEngineApi = '$baseUrl/wp-json/jetelementor/v1';
  static const String wooCommerceApi = '$baseUrl/wp-json/wc/v3';

  // Endpoints
  static const String postsEndpoint = '$wordpressApi/posts';
  static const String productsEndpoint = '$wooCommerceApi/products';
  static const String servicesEndpoint = '$jetEngineApi/services';
  static const String eventsEndpoint = '$jetEngineApi/events';
  static const String usersEndpoint = '$wordpressApi/users';
  static const String categoriesEndpoint = '$wordpressApi/categories';
  static const String tagsEndpoint = '$wordpressApi/tags';
  static const String reviewsEndpoint = '$jetEngineApi/reviews';
  static const String bookingsEndpoint = '$jetEngineApi/bookings';
  static const String ordersEndpoint = '$wooCommerceApi/orders';
  static const String notificationsEndpoint = '$jetEngineApi/notifications';
  static const String faqEndpoint = '$jetEngineApi/faqs';

  // Auth endpoints
  static const String loginEndpoint = '$baseUrl/wp-json/jwt-auth/v1/token';
  static const String validateTokenEndpoint = '$baseUrl/wp-json/jwt-auth/v1/token/validate';
  static const String refreshTokenEndpoint = '$baseUrl/wp-json/jwt-auth/v1/token/refresh';

  // Firebase
  static const String firebaseProjectId = 'your-firebase-project-id';
  static const String firebaseApiKey = 'your-firebase-api-key';
  static const String firebaseAppId = 'your-firebase-app-id';
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
