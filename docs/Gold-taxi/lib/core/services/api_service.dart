import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../interceptors/auth_interceptor.dart';
import 'package:gold_taxi/models/booking_model.dart';
import 'package:gold_taxi/models/faq_model.dart';
import 'package:gold_taxi/models/notification_model.dart';
import 'package:gold_taxi/models/invoice_model.dart';
import 'mock_api_service.dart';

/// Custom API Exception
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// API Service using Dio for HTTP requests with Mock Fallback
class ApiService {
  late Dio _dio;
  final Logger _logger = Logger();
  final AuthInterceptor _authInterceptor;
  bool _useMockData = false;
  static bool _mockModeEnabled = false;

  ApiService(this._authInterceptor, {Dio? dio, bool enableMockMode = false}) {
    _mockModeEnabled = enableMockMode;
    if (dio != null) {
      _dio = dio;
    } else {
      _initializeDio();
    }
  }

  void _initializeDio() {
    String baseUrl = ApiConstants.baseUrl;
    if (!baseUrl.endsWith('/')) {
      baseUrl = '$baseUrl/';
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: AppConstants.apiTimeout,
        receiveTimeout: AppConstants.apiTimeout,
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );

    // Add interceptors
    _dio.interceptors.add(_authInterceptor);
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    _logger.i('🔵 [API] ${options.method} ${options.path}');
    _logger.d('Params: ${options.queryParameters}');
    handler.next(options);
  }

  Future<void> _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    _logger.i('🟢 [API] ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    _logger.e('🔴 [API] Error: ${error.message}');
    // Enable mock mode on connection errors
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.message?.contains('failed host lookup') == true ||
        error.message?.contains('Connection failed') == true) {
      _useMockData = true;
      _mockModeEnabled = true;
      _logger.w('⚠️  Switching to MOCK DATA mode due to connection issues');
    }
    handler.next(error);
  }

  String _normalizeEndpoint(String endpoint) {
    if (endpoint.startsWith('/')) {
      return endpoint.substring(1);
    }
    return endpoint;
  }

  /// Generic GET request with Mock Fallback
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    // If mock mode is enabled, return mock data
    if (_mockModeEnabled || _useMockData) {
      return _getMockData(endpoint, queryParameters);
    }

    try {
      final response = await _dio.get(
        _normalizeEndpoint(endpoint),
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      return response.data;
    } on DioException catch (e) {
      // On connection errors, switch to mock
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        _useMockData = true;
        _mockModeEnabled = true;
        _logger.w('⚠️  API Connection failed, using MOCK DATA: ${e.message}');
        return _getMockData(endpoint, queryParameters);
      }
      throw _handleError(e);
    }
  }

  /// Generic POST request with Mock Fallback
  Future<dynamic> post(
    String endpoint, {
    required Map<String, dynamic> data,
    Map<String, dynamic>? headers,
  }) async {
    if (_mockModeEnabled || _useMockData) {
      return _postMockData(endpoint, data);
    }

    try {
      final response = await _dio.post(
        _normalizeEndpoint(endpoint),
        data: data,
        options: Options(headers: headers),
      );
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        _useMockData = true;
        _mockModeEnabled = true;
        return _postMockData(endpoint, data);
      }
      throw _handleError(e);
    }
  }

  /// Generic PUT request with Mock Fallback
  Future<dynamic> put(
    String endpoint, {
    required Map<String, dynamic> data,
    Map<String, dynamic>? headers,
  }) async {
    if (_mockModeEnabled || _useMockData) {
      return data; // Just return the data for PUT in mock mode
    }

    try {
      final response = await _dio.put(
        _normalizeEndpoint(endpoint),
        data: data,
        options: Options(headers: headers),
      );
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        _useMockData = true;
        _mockModeEnabled = true;
        return data;
      }
      throw _handleError(e);
    }
  }

  /// Generic DELETE request with Mock Fallback
  Future<dynamic> delete(
    String endpoint, {
    Map<String, dynamic>? headers,
  }) async {
    if (_mockModeEnabled || _useMockData) {
      return {'success': true, 'message': 'Mock delete successful'};
    }

    try {
      final response = await _dio.delete(
        _normalizeEndpoint(endpoint),
        options: Options(headers: headers),
      );
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        _useMockData = true;
        _mockModeEnabled = true;
        return {'success': true, 'message': 'Mock delete successful'};
      }
      throw _handleError(e);
    }
  }

  /// Get mock data based on endpoint
  dynamic _getMockData(String endpoint, Map<String, dynamic>? queryParameters) {
    final normEndpoint = _normalizeEndpoint(endpoint).toLowerCase();
    final perPage = queryParameters?['per_page'] as int? ?? 10;

    _logger.i('🎭 [MOCK] Providing mock data for: $normEndpoint');

    // WordPress posts
    if (normEndpoint.contains('/wp-json/wp/v2/posts')) {
      return MockApiService.getMockPosts(count: perPage);
    }
    // WordPress users
    if (normEndpoint.contains('/wp-json/wp/v2/users')) {
      return MockApiService.getMockUsers(count: perPage);
    }
    // WooCommerce products
    if (normEndpoint.contains('/wp-json/wc/v3/products')) {
      return MockApiService.getMockProducts(count: perPage);
    }
    // Categories
    if (normEndpoint.contains('/wp-json/wp/v2/categories')) {
      return [
        {'id': 1, 'name': 'Taxi Služby', 'slug': 'taxi-sluzby'},
        {'id': 2, 'name': 'Akcie', 'slug': 'akcie'},
        {'id': 3, 'name': 'Novinky', 'slug': 'novinky'},
      ];
    }
    // Tags
    if (normEndpoint.contains('/wp-json/wp/v2/tags')) {
      return [
        {'id': 1, 'name': 'Bratislava', 'slug': 'bratislava'},
        {'id': 2, 'name': 'Košice', 'slug': 'kosice'},
        {'id': 3, 'name': 'Letisko', 'slug': 'letisko'},
      ];
    }
    // Media
    if (normEndpoint.contains('/wp-json/wp/v2/media')) {
      return List.generate(5, (i) => {
        'id': 100 + i,
        'source_url': 'https://via.placeholder.com/800x600/FFD700/000000?text=Image+${100 + i}',
        'alt_text': 'Taxi Image ${100 + i}',
      });
    }
    // JetEngine endpoints
    if (normEndpoint.contains('/wp-json/jet-engine/v1/')) {
      final cptName = normEndpoint.split('/').last;
      return MockApiService.getMockCptData(cptName, count: perPage);
    }
    // JWT Auth - Token
    if (normEndpoint.contains('/wp-json/jwt-auth/v1/token')) {
      return {
        'token': 'mock_jwt_token_abc123xyz789',
        'user_email': 'erik.babcan@example.com',
        'user_nicename': 'erik.babcan',
        'user_display_name': 'Erik Babčan',
        'expires_in': 3600,
      };
    }
    // JWT Auth - Validate
    if (normEndpoint.contains('/wp-json/jwt-auth/v1/token/validate')) {
      return {'code': 'jwt_auth_valid_token', 'data': {'status': 200}};
    }

    // Default fallback
    return MockApiService.getMockPosts(count: perPage);
  }

  /// Handle POST requests in mock mode
  dynamic _postMockData(String endpoint, Map<String, dynamic> data) {
    final normEndpoint = _normalizeEndpoint(endpoint).toLowerCase();

    _logger.i('🎭 [MOCK POST] $normEndpoint with data: ${data.keys}');

    // Login endpoint
    if (normEndpoint.contains('/wp-json/jwt-auth/v1/token')) {
      return {
        'token': 'mock_jwt_token_abc123xyz789',
        'user_email': data['username'] ?? 'erik.babcan@example.com',
        'user_nicename': 'erik.babcan',
        'user_display_name': 'Erik Babčan',
        'expires_in': 3600,
      };
    }
    // Bookings
    if (normEndpoint.contains('booking') || normEndpoint.contains('bookings')) {
      final booking = MockApiService.getMockBookings(count: 1)[0];
      return {
        ...booking,
        'message': 'Objednávka úspešne vytvorená (MOCK)',
        'success': true,
      };
    }
    // Reviews
    if (normEndpoint.contains('review') || normEndpoint.contains('reviews')) {
      return {
        'id': 1,
        'message': 'Hodnotenie úspešne pridané (MOCK)',
        'success': true,
      };
    }

    return {'success': true, 'message': 'Mock POST successful', 'data': data};
  }

  /// Error handling
  Exception _handleError(DioException error) {
    String message = 'Unknown error';
    int? statusCode = error.response?.statusCode;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Connection timeout';
        break;
      case DioExceptionType.sendTimeout:
        message = 'Send timeout';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Receive timeout';
        break;
      case DioExceptionType.badResponse:
        if (statusCode == 401) {
          message = 'Unauthorized - Please login';
        } else if (statusCode == 403) {
          message = 'Forbidden';
        } else if (statusCode == 404) {
          message = 'Not found';
        } else if (statusCode == 500) {
          message = 'Server error';
        } else {
          message = 'Error: $statusCode';
        }
        break;
      case DioExceptionType.cancel:
        message = 'Request cancelled';
        break;
      case DioExceptionType.unknown:
        message = 'Unknown error: ${error.message}';
        break;
      case DioExceptionType.badCertificate:
        message = 'Bad certificate';
        break;
      case DioExceptionType.connectionError:
        message = 'Connection error';
        break;
    }
    return ApiException(message, statusCode: statusCode);
  }

  // In-memory route availability cache
  final Map<String, bool> _endpointAvailability = {};

  /// Verify if endpoint exists by sending a lightweight probe (per_page=1)
  Future<bool> _isEndpointAvailable(String endpoint) async {
    // In mock mode, always return true
    if (_mockModeEnabled || _useMockData) {
      return true;
    }

    final normPath = _normalizeEndpoint(endpoint);
    if (_endpointAvailability.containsKey(normPath)) {
      return _endpointAvailability[normPath]!;
    }
    try {
      await _dio.get(normPath, queryParameters: {'per_page': 1});
      _endpointAvailability[normPath] = true;
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        _endpointAvailability[normPath] = false;
        return false;
      }
      // On connection errors, enable mock mode
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        _useMockData = true;
        _mockModeEnabled = true;
      }
      return false; // Network issue, don't cache permanently as unavailable
    } catch (_) {
      return false;
    }
  }

  /// Generic CPT fetcher implementing the fallbacks with Mock support
  Future<List<Map<String, dynamic>>> fetchCptData(
    String cptName, {
    int page = 1,
    int perPage = 10,
  }) async {
    // In mock mode, return mock data immediately
    if (_mockModeEnabled || _useMockData) {
      return MockApiService.getMockCptData(cptName, count: perPage);
    }

    final queryParams = {
      'page': page,
      'per_page': perPage,
      '_embed': 1,
    };

    // 1. Check WordPress CPT route
    final wpCptRoute = '/wp-json/wp/v2/$cptName';
    if (await _isEndpointAvailable(wpCptRoute)) {
      try {
        final response = await get(wpCptRoute, queryParameters: queryParams);
        if (response is List) {
          return response.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        }
      } catch (e) {
        _logger.w('CPT fetch failed from $wpCptRoute: $e. Using fallback...');
      }
    }

    // 2. Check JetEngine custom endpoint
    final jetRoute = '/wp-json/jet-engine/v1/$cptName';
    if (await _isEndpointAvailable(jetRoute)) {
      try {
        final response = await get(jetRoute, queryParameters: queryParams);
        if (response is List) {
          return response.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        }
      } catch (e) {
        _logger.w('JetEngine fetch failed from $jetRoute: $e. Using fallback...');
      }
    }

    // 3. Fallback to standard posts filtered by type
    const postsRoute = '/wp-json/wp/v2/posts';
    final fallbackParams = Map<String, dynamic>.from(queryParams)..['type'] = cptName;
    try {
      final response = await get(postsRoute, queryParameters: fallbackParams);
      if (response is List) {
        return response.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      }
    } catch (e) {
      _logger.e('All fallbacks failed for CPT $cptName: $e');
      // Return mock data as final fallback
      return MockApiService.getMockCptData(cptName, count: perPage);
    }
    return [];
  }

  // Typed CPT getters
  Future<List<BookingModel>> getBookings({int page = 1, int perPage = 10}) async {
    final raw = await fetchCptData('booking', page: page, perPage: perPage);
    return raw.map((json) => BookingModel.fromJson(json)).toList();
  }

  Future<List<NotificationModel>> getNotifications({int page = 1, int perPage = 10}) async {
    final raw = await fetchCptData('notification', page: page, perPage: perPage);
    return raw.map((json) => NotificationModel.fromJson(json)).toList();
  }

  Future<List<FaqModel>> getFAQs({int page = 1, int perPage = 10}) async {
    final raw = await fetchCptData('faq', page: page, perPage: perPage);
    return raw.map((json) => FaqModel.fromJson(json)).toList();
  }

  Future<List<InvoiceModel>> getInvoices({int page = 1, int perPage = 100}) async {
    final raw = await fetchCptData('invoices', page: page, perPage: perPage);
    return raw.map((json) => InvoiceModel.fromJson(json)).toList();
  }

  /// Enable mock mode manually (for testing)
  static void enableMockMode() {
    _mockModeEnabled = true;
  }

  /// Disable mock mode manually
  static void disableMockMode() {
    _mockModeEnabled = false;
  }

  /// Check if mock mode is enabled
  static bool isMockModeEnabled() {
    return _mockModeEnabled;
  }

  /// Close Dio instance
  void close() {
    _dio.close();
  }
}
