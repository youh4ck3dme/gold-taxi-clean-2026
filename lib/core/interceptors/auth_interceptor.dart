import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../services/local_storage_service.dart';

import '../constants/api_constants.dart';

class AuthInterceptor extends QueuedInterceptor {
  final LocalStorageService _storage;

  AuthInterceptor(this._storage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.path.contains('wp-json/wc/v3')) {
      final key = ApiConstants.wooCommerceConsumerKey;
      final secret = ApiConstants.wooCommerceConsumerSecret;
      debugPrint('AuthInterceptor: WooCommerce request detected! Path: ${options.path}, Key: $key, Secret: $secret');
      if (key.isNotEmpty && secret.isNotEmpty) {
        options.queryParameters['consumer_key'] = key;
        options.queryParameters['consumer_secret'] = secret;
      } else {
        debugPrint('AuthInterceptor: Warning! WooCommerce key or secret is empty!');
      }
    } else {
      final token = await _storage.getToken();
      if (token != null && token.isNotEmpty && token != 'null') {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await _storage.deleteToken();
    }
    handler.next(err);
  }
}
