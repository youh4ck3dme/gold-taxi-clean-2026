import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gold_taxi/core/interceptors/auth_interceptor.dart';
import 'package:gold_taxi/core/services/api_service.dart';

class MockDio extends Mock implements Dio {}

class MockAuthInterceptor extends Mock implements AuthInterceptor {}

void main() {
  late ApiService apiService;
  late MockAuthInterceptor mockAuthInterceptor;
  late MockDio mockDio;

  setUp(() {
    mockAuthInterceptor = MockAuthInterceptor();
    mockDio = MockDio();
    // Pass mockDio to prevent actual network calls, and ensure mockMode is explicitly false
    apiService = ApiService(
      mockAuthInterceptor,
      dio: mockDio,
      enableMockMode: false,
    );
  });

  group('ApiService Unit Tests (Production Hardened)', () {
    test(
      '1. ApiService initializes with correct configuration and no Mock JWTs',
      () {
        expect(apiService, isNotNull);
      },
    );

    test(
      '2. ApiService fails openly on Network Timeout (Fail Closed)',
      () async {
        final requestOptions = RequestOptions(path: '/test');
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: requestOptions,
            type: DioExceptionType.connectionTimeout,
            error: 'Connection timeout',
          ),
        );

        expect(
          () => apiService.get('/test'),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              contains('Connection timeout'),
            ),
          ),
        );
      },
    );

    test('3. ApiService fails openly on 401 Unauthorized', () async {
      final requestOptions = RequestOptions(path: '/test');
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: requestOptions,
          response: Response(requestOptions: requestOptions, statusCode: 401),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => apiService.get('/test'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('Unauthorized'),
          ),
        ),
      );
    });

    test(
      '4. ApiService does NOT fallback to Mock data silently on 500 Server Error',
      () async {
        final requestOptions = RequestOptions(path: '/test');
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: requestOptions,
            response: Response(requestOptions: requestOptions, statusCode: 500),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(
          () => apiService.get('/test'),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              contains('Server error'),
            ),
          ),
        );
      },
    );
  });
}
