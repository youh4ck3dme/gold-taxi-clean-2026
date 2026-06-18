import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gold_taxi/core/services/api_service.dart';
import 'package:gold_taxi/core/interceptors/auth_interceptor.dart';
import 'package:gold_taxi/core/services/local_storage_service.dart';
import 'package:gold_taxi/models/faq_model.dart';
import 'package:gold_taxi/models/notification_model.dart';

class MockDio extends Mock implements Dio {}

class MockLocalStorageService extends Mock implements LocalStorageService {}

void main() {
  late MockDio mockDio;
  late ApiService apiService;

  setUp(() {
    mockDio = MockDio();
    final options = BaseOptions(baseUrl: 'https://test.com/');
    when(() => mockDio.options).thenReturn(options);

    apiService = ApiService(
      AuthInterceptor(MockLocalStorageService()),
      dio: mockDio,
    );
  });

  group('CPT Routing & Caching Tests', () {
    test(
      'WP CPT is available: fetches directly from /wp-json/wp/v2/booking',
      () async {
        // 1. Stub the probe request (per_page=1) to return 200
        when(
          () => mockDio.get(
            'wp-json/wp/v2/booking',
            queryParameters: {'per_page': 1},
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: 'wp-json/wp/v2/booking'),
            statusCode: 200,
          ),
        );

        // 2. Stub the actual fetch request
        when(
          () => mockDio.get(
            'wp-json/wp/v2/booking',
            queryParameters: {'page': 1, 'per_page': 10, '_embed': 1},
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: 'wp-json/wp/v2/booking'),
            statusCode: 200,
            data: [
              {
                'id': 123,
                'service_id': 5,
                'booking_date': '2026-06-11T12:00:00.000Z',
                'time_slot': '10:00',
                'status': 'confirmed',
              },
            ],
          ),
        );

        // Execute
        final bookings = await apiService.getBookings();

        expect(bookings, hasLength(1));
        expect(bookings.first.id, 123);
        expect(bookings.first.serviceId, 5);
        expect(bookings.first.timeSlot, '10:00');
        expect(bookings.first.status, 'confirmed');

        // Verify probe was called once
        verify(
          () => mockDio.get(
            'wp-json/wp/v2/booking',
            queryParameters: {'per_page': 1},
          ),
        ).called(1);
      },
    );

    test(
      'WP CPT 404s, but JetEngine is available: fetches from /wp-json/jet-engine/v1/booking',
      () async {
        // 1. Probe wp route -> returns 404
        when(
          () => mockDio.get(
            'wp-json/wp/v2/booking',
            queryParameters: {'per_page': 1},
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: 'wp-json/wp/v2/booking'),
            response: Response(
              requestOptions: RequestOptions(path: 'wp-json/wp/v2/booking'),
              statusCode: 404,
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        // 2. Probe jet route -> returns 200
        when(
          () => mockDio.get(
            'wp-json/jet-engine/v1/booking',
            queryParameters: {'per_page': 1},
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(
              path: 'wp-json/jet-engine/v1/booking',
            ),
            statusCode: 200,
          ),
        );

        // 3. Stub the actual fetch from jet route
        when(
          () => mockDio.get(
            'wp-json/jet-engine/v1/booking',
            queryParameters: {'page': 1, 'per_page': 10, '_embed': 1},
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(
              path: 'wp-json/jet-engine/v1/booking',
            ),
            statusCode: 200,
            data: [
              {
                'id': 456,
                'meta': {
                  'service_id': '8',
                  'booking_date': '2026-06-11T13:00:00.000Z',
                  'time_slot': '11:00',
                  'status': 'pending',
                },
              },
            ],
          ),
        );

        // Execute
        final bookings = await apiService.getBookings();

        expect(bookings, hasLength(1));
        expect(bookings.first.id, 456);
        expect(bookings.first.serviceId, 8);
        expect(bookings.first.timeSlot, '11:00');

        verify(
          () => mockDio.get(
            'wp-json/wp/v2/booking',
            queryParameters: {'per_page': 1},
          ),
        ).called(1);
        verify(
          () => mockDio.get(
            'wp-json/jet-engine/v1/booking',
            queryParameters: {'per_page': 1},
          ),
        ).called(1);
      },
    );

    test(
      'All CPT routes 404: falls back to /wp-json/wp/v2/posts?type=booking',
      () async {
        // 1. Probe wp route -> 404
        when(
          () => mockDio.get(
            'wp-json/wp/v2/booking',
            queryParameters: {'per_page': 1},
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: 'wp-json/wp/v2/booking'),
            response: Response(
              requestOptions: RequestOptions(path: 'wp-json/wp/v2/booking'),
              statusCode: 404,
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        // 2. Probe jet route -> 404
        when(
          () => mockDio.get(
            'wp-json/jet-engine/v1/booking',
            queryParameters: {'per_page': 1},
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(
              path: 'wp-json/jet-engine/v1/booking',
            ),
            response: Response(
              requestOptions: RequestOptions(
                path: 'wp-json/jet-engine/v1/booking',
              ),
              statusCode: 404,
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        // 3. Stub the actual fallback request
        when(
          () => mockDio.get(
            'wp-json/wp/v2/posts',
            queryParameters: {
              'page': 1,
              'per_page': 10,
              '_embed': 1,
              'type': 'booking',
            },
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: 'wp-json/wp/v2/posts'),
            statusCode: 200,
            data: [
              {
                'id': 789,
                'acf': {
                  'service_id': 10,
                  'booking_date': '2026-06-11T14:00:00.000Z',
                  'time_slot': '12:00',
                  'status': 'cancelled',
                },
              },
            ],
          ),
        );

        // Execute
        final bookings = await apiService.getBookings();

        expect(bookings, hasLength(1));
        expect(bookings.first.id, 789);
        expect(bookings.first.serviceId, 10);
        expect(bookings.first.timeSlot, '12:00');
        expect(bookings.first.status, 'cancelled');
      },
    );

    test(
      'Endpoint caching: probe check is only called once per route',
      () async {
        when(
          () => mockDio.get(
            'wp-json/wp/v2/booking',
            queryParameters: {'per_page': 1},
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: 'wp-json/wp/v2/booking'),
            statusCode: 200,
          ),
        );

        when(
          () => mockDio.get(
            'wp-json/wp/v2/booking',
            queryParameters: {'page': 1, 'per_page': 10, '_embed': 1},
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: 'wp-json/wp/v2/booking'),
            statusCode: 200,
            data: [],
          ),
        );

        await apiService.getBookings();
        await apiService.getBookings();

        verify(
          () => mockDio.get(
            'wp-json/wp/v2/booking',
            queryParameters: {'per_page': 1},
          ),
        ).called(1);
      },
    );
  });

  group('Model Deserialization Tests', () {
    test(
      'FaqModel parsing resiliently maps fields from custom field or wp post title/content',
      () {
        final faqJson = {
          'id': 1,
          'title': {'rendered': 'Čo je to Gold Taxi?'},
          'content': {'rendered': 'Gold Taxi je prémiová taxislužba.'},
          'meta': {'category': 'Služby'},
        };

        final faq = FaqModel.fromJson(faqJson);

        expect(faq.id, '1');
        expect(faq.question, 'Čo je to Gold Taxi?');
        expect(faq.answer, 'Gold Taxi je prémiová taxislužba.');
        expect(faq.category, 'Služby');
      },
    );

    test('NotificationModel parses fields from acf namespaces', () {
      final notificationJson = {
        'id': 99,
        'title': {'rendered': 'Nová objednávka'},
        'acf': {'message': 'Máte novú jazdu!', 'is_read': 'true'},
        'date': '2026-06-11T12:00:00.000Z',
      };

      final notification = NotificationModel.fromJson(notificationJson);

      expect(notification.id, 99);
      expect(notification.title, 'Nová objednávka');
      expect(notification.message, 'Máte novú jazdu!');
      expect(notification.isRead, isTrue);
    });
  });
}
