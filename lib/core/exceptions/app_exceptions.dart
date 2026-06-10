/// App Exceptions for error handling
abstract class AppException implements Exception {
  final String message;
  final String? code;

  AppException({required this.message, this.code});

  @override
  String toString() => message;
}

/// Network related exceptions
class NetworkException extends AppException {
  NetworkException({
    required super.message,
    String? code,
  }) : super(code: code ?? 'NETWORK_ERROR');
}

/// API related exceptions
class ApiException extends AppException {
  final int? statusCode;

  ApiException({
    required super.message,
    this.statusCode,
    String? code,
  }) : super(code: code ?? 'API_ERROR');
}

/// Authentication related exceptions
class AuthException extends AppException {
  AuthException({
    required super.message,
    String? code,
  }) : super(code: code ?? 'AUTH_ERROR');
}

/// Cache related exceptions
class CacheException extends AppException {
  CacheException({
    required super.message,
    String? code,
  }) : super(code: code ?? 'CACHE_ERROR');
}

/// Validation related exceptions
class ValidationException extends AppException {
  final Map<String, String>? errors;

  ValidationException({
    required super.message,
    this.errors,
    String? code,
  }) : super(code: code ?? 'VALIDATION_ERROR');
}

/// Generic app exception
class GeneralException extends AppException {
  GeneralException({
    required super.message,
    String? code,
  }) : super(code: code ?? 'GENERAL_ERROR');
}
