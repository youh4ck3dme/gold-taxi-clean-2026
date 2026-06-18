import 'package:flutter_test/flutter_test.dart';
import 'package:gold_taxi/models/product_model.dart';
import 'package:gold_taxi/models/service_model.dart';
import 'package:gold_taxi/models/event_model.dart';
import 'package:gold_taxi/models/review_model.dart';
import 'package:gold_taxi/models/booking_model.dart';
import 'package:gold_taxi/models/faq_model.dart';
import 'package:gold_taxi/models/post_model.dart';

void main() {
  group('Model Serialization Tests', () {
    test('ProductModel parses WooCommerce JSON correctly', () {
      final json = {
        'id': 101,
        'name': 'Test Taxi Product',
        'description': '<p>Premium taxi merchandise</p>',
        'price': '15.99',
        'sale_price': '12.99',
        'sku': 'TAXI-001',
        'stock_quantity': 5,
        'images': [
          {'src': 'https://example.com/image.png'}
        ],
        'categories': [
          {'name': 'Merch'}
        ],
      };

      final product = ProductModel.fromJson(json);

      expect(product.id, '101');
      expect(product.name, 'Test Taxi Product');
      expect(product.price, 15.99);
      expect(product.stock, 5);
      expect(product.images.first, 'https://example.com/image.png');
      expect(product.categories.first, 'Merch');

      final serialized = product.toJson();
      expect(serialized['id'], '101');
      expect(serialized['price'], 15.99);
    });

    test('ServiceModel parses JetEngine JSON correctly', () {
      final json = {
        'id': 201,
        'name': 'VIP Airport Shuttle',
        'description': 'Luxury shuttle service',
        'price': 45.0,
        'rating': 4.8,
        'review_count': 12,
        'provider': 'Gold Taxi Express',
        'category': 'Shuttle',
        'images': ['https://example.com/shuttle.png'],
      };

      final service = ServiceModel.fromJson(json);

      expect(service.id, 201);
      expect(service.name, 'VIP Airport Shuttle');
      expect(service.price, 45.0);
      expect(service.rating, 4.8);
      expect(service.reviewCount, 12);
      expect(service.provider, 'Gold Taxi Express');
      expect(service.category, 'Shuttle');
      expect(service.images.first, 'https://example.com/shuttle.png');
    });

    test('EventModel parses JetEngine JSON correctly', () {
      final json = {
        'id': 301,
        'title': 'Grand Taxi Gala',
        'description': 'Annual driver celebration event',
        'start_date': '2026-12-15T18:00:00Z',
        'end_date': '2026-12-15T23:30:00Z',
        'location': 'Grand Hotel Bratislava',
        'latitude': '48.1485',
        'longitude': '17.1077',
        'category': 'Celebration',
        'price': '25.0',
        'images': [
          {'url': 'https://example.com/gala.png'}
        ],
      };

      final event = EventModel.fromJson(json);

      expect(event.id, 301);
      expect(event.title, 'Grand Taxi Gala');
      expect(event.startDate, DateTime.parse('2026-12-15T18:00:00Z'));
      expect(event.location, 'Grand Hotel Bratislava');
      expect(event.latitude, 48.1485);
      expect(event.longitude, 17.1077);
      expect(event.category, 'Celebration');
      expect(event.price, 25.0);
      expect(event.images.first, 'https://example.com/gala.png');
    });

    test('ReviewModel parses review JSON correctly', () {
      final json = {
        'id': 401,
        'author_name': 'Jan Novak',
        'author_email': 'jan.novak@example.com',
        'rating': 5,
        'comment': 'Perfect service, friendly driver!',
        'date': '2026-06-10T14:30:00Z',
        'post_id': 101,
      };

      final review = ReviewModel.fromJson(json);

      expect(review.id, 401);
      expect(review.authorName, 'Jan Novak');
      expect(review.authorEmail, 'jan.novak@example.com');
      expect(review.rating, 5);
      expect(review.comment, 'Perfect service, friendly driver!');
      expect(review.postId, 101);
    });

    test('BookingModel parses booking JSON correctly', () {
      final json = {
        'id': 501,
        'service_id': 201,
        'booking_date': '2026-06-12T00:00:00Z',
        'time_slot': '14:00',
        'status': 'confirmed',
      };

      final booking = BookingModel.fromJson(json);

      expect(booking.id, 501);
      expect(booking.serviceId, 201);
      expect(booking.bookingDate, DateTime.parse('2026-06-12T00:00:00Z'));
      expect(booking.timeSlot, '14:00');
      expect(booking.status, 'confirmed');
    });

    test('FaqModel parses FAQ JSON correctly', () {
      final json = {
        'id': 601,
        'question': 'How to pay?',
        'answer': 'You can pay by card or cash.',
        'category': 'Payments',
      };

      final faq = FaqModel.fromJson(json);

      expect(faq.id, '601');
      expect(faq.question, 'How to pay?');
      expect(faq.answer, 'You can pay by card or cash.');
      expect(faq.category, 'Payments');
    });

    test('PostModel parses WP JSON correctly and extracts embedded info', () {
      final json = {
        'id': 701,
        'title': {'rendered': 'Novinky z Gold Taxi'},
        'content': {'rendered': 'Dnes otvárame novú pobočku.'},
        'date': '2026-06-11T12:00:00Z',
        'slug': 'novinky-z-gold-taxi',
        'author': 4,
        'categories': [2, 3],
        'tags': [5],
        '_embedded': {
          'author': [
            {'name': 'Jozef Admin'}
          ],
          'wp:featuredmedia': [
            {'source_url': 'https://example.com/taxi-pobocka.png'}
          ],
          'wp:term': [
            [
              {'name': 'Správy', 'taxonomy': 'category'},
              {'name': 'Novinky', 'taxonomy': 'category'}
            ]
          ]
        }
      };

      final post = PostModel.fromJson(json);

      expect(post.id, '701');
      expect(post.title, 'Novinky z Gold Taxi');
      expect(post.content, 'Dnes otvárame novú pobočku.');
      expect(post.excerpt, '');
      expect(post.featuredImageUrl, 'https://example.com/taxi-pobocka.png');
      expect(post.authorName, 'Jozef Admin');
    });
  });
}
