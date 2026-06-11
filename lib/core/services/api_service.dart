import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../interceptors/auth_interceptor.dart';
import 'package:gold_taxi/models/booking_model.dart';
import 'package:gold_taxi/models/faq_model.dart';
import 'package:gold_taxi/models/notification_model.dart';
import 'package:gold_taxi/models/invoice_model.dart';

/// Custom API Exception
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// API Service using Dio for HTTP requests
class ApiService {
  late Dio _dio;
  final Logger _logger = Logger();
  final AuthInterceptor _authInterceptor;

  ApiService(this._authInterceptor, {Dio? dio}) {
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
    handler.next(error);
  }

  String _normalizeEndpoint(String endpoint) {
    if (endpoint.startsWith('/')) {
      return endpoint.substring(1);
    }
    return endpoint;
  }

  /// Generic GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.get(
        _normalizeEndpoint(endpoint),
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Generic POST request
  Future<dynamic> post(
    String endpoint, {
    required Map<String, dynamic> data,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.post(
        _normalizeEndpoint(endpoint),
        data: data,
        options: Options(headers: headers),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Generic PUT request
  Future<dynamic> put(
    String endpoint, {
    required Map<String, dynamic> data,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.put(
        _normalizeEndpoint(endpoint),
        data: data,
        options: Options(headers: headers),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Generic DELETE request
  Future<dynamic> delete(
    String endpoint, {
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.delete(
        _normalizeEndpoint(endpoint),
        options: Options(headers: headers),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
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
      return false; // Network issue, don't cache permanently as unavailable
    } catch (_) {
      return false;
    }
  }

  /// Generic CPT fetcher implementing the fallbacks:
  /// 1. WordPress CPT endpoint (/wp-json/wp/v2/<cpt>)
  /// 2. JetEngine API endpoint (/wp-json/jet-engine/v1/<cpt>)
  /// 3. WordPress posts with type filter (/wp-json/wp/v2/posts?type=<cpt>)
  Future<List<Map<String, dynamic>>> fetchCptData(
    String cptName, {
    int page = 1,
    int perPage = 10,
  }) async {
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
      throw ApiException('Nepodarilo sa načítať dáta pre $cptName', statusCode: 500);
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

  /// Close Dio instance
  void close() {
    _dio.close();
  }
}
