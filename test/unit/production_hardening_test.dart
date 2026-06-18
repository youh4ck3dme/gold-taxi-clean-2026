import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:gold_taxi/core/services/api_service.dart';
import 'package:gold_taxi/core/interceptors/auth_interceptor.dart';
import 'package:gold_taxi/features/earnings/presentation/cubits/earnings_cubit.dart';
import 'package:gold_taxi/features/earnings/presentation/cubits/earnings_state.dart';
import 'package:gold_taxi/features/earnings/data/repositories/earnings_repository.dart';

class MockDio extends Mock implements Dio {}

class MockAuthInterceptor extends Mock implements AuthInterceptor {}

class MockEarningsRepository extends Mock implements EarningsRepository {}

void main() {
  group('Production Hardening Regression Tests', () {
    test('1. pubspec.yaml must not contain packaged .env assets', () {
      final file = File('pubspec.yaml');
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();
      // It must not contain "- .env" or similar asset pattern
      expect(content.contains(RegExp(r'-\s+\.env')), isFalse);
    });

    test(
      '2. ApiService must not contain mock manufacturing code or fallback logic',
      () {
        final file = File('lib/core/services/api_service.dart');
        expect(file.existsSync(), isTrue);

        final content = file.readAsStringSync();

        // Prohibited mock/fallback strings in core ApiService
        final prohibited = [
          'mock_'
              'jwt_'
              'token',
          'mock_'
              'jwt_'
              'token_'
              'abc123xyz789',
          '_mock'
              'Mode'
              'Enabled',
          'ApiService.'
              'enable'
              'MockMode',
          'ApiService.'
              'disable'
              'MockMode',
        ];

        for (final term in prohibited) {
          expect(
            content.contains(term),
            isFalse,
            reason: 'ApiService must not contain $term',
          );
        }
      },
    );

    test(
      '3. ApiService Dio connection timeout throws ApiException with timeout message (no mock fallback)',
      () async {
        final mockDio = MockDio();
        final mockInterceptor = MockAuthInterceptor();

        final apiService = ApiService(mockInterceptor, dio: mockDio);

        final requestOptions = RequestOptions(path: 'test-endpoint');

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
          () => apiService.get('test-endpoint'),
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

    test(
      '4. EarningsCubit throws EarningsError immediately when driverId is empty',
      () async {
        final mockRepo = MockEarningsRepository();
        final cubit = EarningsCubit(earningsRepository: mockRepo, driverId: '');

        expectLater(
          cubit.stream,
          emits(
            isA<EarningsError>().having(
              (e) => e.message,
              'message',
              contains('Neautorizovaný prístup. ID vodiča chýba.'),
            ),
          ),
        );

        await cubit.loadEarningsSummary();
        await cubit.close();
      },
    );
  });
}
