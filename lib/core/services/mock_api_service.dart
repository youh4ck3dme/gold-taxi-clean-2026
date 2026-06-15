import 'dart:math';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:gold_taxi/core/interceptors/auth_interceptor.dart';
import 'api_service.dart';

/// Mock API Service - Returns realistic mock data for demo purposes
class MockApiService extends ApiService {
  final Logger _logger = Logger();
  static final _random = Random();

  static final List<String> _firstNames = ['Ján', 'Peter', 'Martin', 'Lucia', 'Eva', 'Marek', 'Zuzana', 'Michal', 'Katarína', 'Jozef'];
  static final List<String> _lastNames = ['Novák', 'Kováč', 'Horváth', 'Varga', 'Tóth', 'Nagy', 'Kzlich', 'Babčán', 'Dudáš', 'Lukáč'];
  static final List<String> _cities = ['Bratislava', 'Košice', 'Prešov', 'Žilina', 'Banská Bystrica', 'Nitra', 'Trnava', 'Trenčín'];
  static final List<String> _streets = ['Hlavná', 'Nová', 'Stará', 'Lesná', 'Polná', 'Jarná', 'Letná', 'Zimná'];
  static final List<String> _carModels = ['Škoda Octavia', 'Volkswagen Passat', 'Toyota Corolla', 'Ford Focus', 'Renault Megane', 'Hyundai i30', 'Kia Ceed'];
  static final List<String> _services = ['Standard', 'Premium', 'Business', 'Eco', 'Van', 'Ladies'];
  static final List<String> _providers = ['Gold-Taxi', 'Taxi Bratislava', 'City Taxi', 'Euro Taxi'];

  MockApiService(super.authInterceptor)
      : super(enableMockMode: true);

  @override
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    return _getMockData(endpoint, queryParameters);
  }

  @override
  Future<dynamic> post(
    String endpoint, {
    required Map<String, dynamic> data,
    Map<String, dynamic>? headers,
  }) async {
    return _postMockData(endpoint, data);
  }

  @override
  Future<dynamic> put(
    String endpoint, {
    required Map<String, dynamic> data,
    Map<String, dynamic>? headers,
  }) async {
    return data;
  }

  @override
  Future<dynamic> delete(
    String endpoint, {
    Map<String, dynamic>? headers,
  }) async {
    return {'success': true, 'message': 'Mock delete successful'};
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCptData(
    String cptName, {
    int page = 1,
    int perPage = 10,
  }) async {
    return getMockCptData(cptName, count: perPage);
  }

  // Generate mock CPT data (generic)
  static List<Map<String, dynamic>> getMockCptData(String cptName, {int count = 10}) {
    final lowerName = cptName.toLowerCase();
    
    switch (lowerName) {
      case 'booking':
        return getMockBookings(count: count);
      case 'notification':
        return getMockNotifications(count: count);
      case 'faq':
        return getMockFAQs(count: count);
      case 'invoices':
      case 'invoice':
        return getMockInvoices(count: count);
      case 'service':
      case 'services':
        return getMockServices(count: count);
      case 'event':
      case 'events':
        return getMockEvents(count: count);
      case 'product':
      case 'products':
        return getMockProducts(count: count);
      case 'user':
      case 'users':
        return getMockUsers(count: count);
      case 'post':
      case 'posts':
      default:
        return getMockPosts(count: count);
    }
  }

  /// Get mock data based on endpoint
  dynamic _getMockData(String endpoint, Map<String, dynamic>? queryParameters) {
    final normEndpoint = normalizeEndpoint(endpoint).toLowerCase();
    final perPage = queryParameters?['per_page'] as int? ?? 10;

    _logger.i('🎭 [MOCK] Providing mock data for: $normEndpoint');

    // WordPress posts
    if (normEndpoint.contains('/wp-json/wp/v2/posts')) {
      return getMockPosts(count: perPage);
    }
    // WordPress users
    if (normEndpoint.contains('/wp-json/wp/v2/users')) {
      return getMockUsers(count: perPage);
    }
    // WooCommerce products
    if (normEndpoint.contains('/wp-json/wc/v3/products')) {
      return getMockProducts(count: perPage);
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
      return getMockCptData(cptName, count: perPage);
    }
    // JWT Auth - Token
    if (normEndpoint.contains('/wp-json/jwt-auth/v1/token')) {
      return {
        'token': 'dev_auth_token_value',
        'user_email': 'erik.babcan@example.com',
        'user_nicename': 'erik.babcan',
        'user_display_name': 'Erik Babčan',
        'expires_in': 3600,
      };
    }
    // JWT Auth - Validate
    if (normEndpoint.contains('/wp-json/jwt-auth/v1/token/validate')) {
      return {'code': 'dev_auth_valid_status', 'data': {'status': 200}};
    }

    // Default fallback
    return getMockPosts(count: perPage);
  }

  /// Handle POST requests in mock mode
  dynamic _postMockData(String endpoint, Map<String, dynamic> data) {
    final normEndpoint = normalizeEndpoint(endpoint).toLowerCase();

    _logger.i('🎭 [MOCK POST] $normEndpoint with data: ${data.keys}');

    // Login endpoint
    if (normEndpoint.contains('/wp-json/jwt-auth/v1/token')) {
      return {
        'token': 'dev_auth_token_value',
        'user_email': data['username'] ?? 'erik.babcan@example.com',
        'user_nicename': 'erik.babcan',
        'user_display_name': 'Erik Babčan',
        'expires_in': 3600,
      };
    }
    // Bookings
    if (normEndpoint.contains('booking') || normEndpoint.contains('bookings')) {
      final booking = getMockBookings(count: 1)[0];
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

  // Generate random date within last 30 days
  static DateTime _randomDate() {
    return DateTime.now().subtract(Duration(days: _random.nextInt(30)));
  }

  // Generate random future date
  static DateTime _randomFutureDate() {
    return DateTime.now().add(Duration(days: _random.nextInt(14) + 1));
  }

  // Generate random price
  static double _randomPrice() {
    return 5.0 + (_random.nextDouble() * 45.0);
  }

  // Generate random rating
  static double _randomRating() {
    return 3.0 + (_random.nextDouble() * 2.0);
  }

  // Generate mock posts (blog articles)
  static List<Map<String, dynamic>> getMockPosts({int count = 10}) {
    return List.generate(count, (index) => {
      'id': index + 1,
      'date': _randomDate().toIso8601String(),
      'title': {
        'rendered': 'Ako objednať taxi cez Gold-Taxi: Príručka pre začičínajúcich'
      },
      'content': {
        'rendered': 'Vítame vás v Gold-Taxi! Objednajte si taxi jednoducho cez našu aplikáciu...'
      },
      'excerpt': {
        'rendered': 'Návod na používanie aplikácie Gold-Taxi'
      },
      'author': _random.nextInt(10) + 1,
      'featured_media': _random.nextInt(5) + 100,
      'categories': [1, 2],
      'tags': [5, 8, 12],
      '_embedded': {
        'wp:featuredmedia': [
          {
            'id': 100 + index,
            'source_url': 'https://via.placeholder.com/800x400/FFD700/000000?text=Blog+${index + 1}',
          }
        ]
      },
    });
  }

  // Generate mock products (taxi services as products)
  static List<Map<String, dynamic>> getMockProducts({int count = 6}) {
    return List.generate(count, (index) => {
      'id': index + 1,
      'name': _services[index % _services.length],
      'slug': _services[index % _services.length].toLowerCase(),
      'description': 'Taxi služba ${_services[index % _services.length]} - komfortné a rýchle prepravenie',
      'short_description': 'Rýchla a spoľahlivá taxi služba',
      'price': _randomPrice().toStringAsFixed(2),
      'regular_price': (_randomPrice() + 5).toStringAsFixed(2),
      'sale_price': '',
      'stock_status': 'instock',
      'stock_quantity': null,
      'images': [
        {'id': 200 + index, 'src': 'https://via.placeholder.com/400x300/FFD700/000000?text=Taxi+${_services[index % _services.length]}'}
      ],
      'categories': [
        {'id': 1, 'name': 'Taxi Služby', 'slug': 'taxi-sluzby'}
      ],
      'tags': [
        {'id': 1, 'name': 'Bratislava', 'slug': 'bratislava'}
      ],
      'meta_data': [
        {'id': 1, 'key': 'duration', 'value': '${_random.nextInt(30) + 10} min'},
        {'id': 2, 'key': 'capacity', 'value': '${_random.nextInt(3) + 2}'},
      ],
      'on_sale': false,
      'purchasable': true,
      'virtual': true,
      'downloadable': false,
      'external_url': '',
      'button_text': '',
      'price_html': '<span class="woocommerce-Price-amount amount"><bdi>€${_randomPrice().toStringAsFixed(2)}</bdi></span>',
      'average_rating': _randomRating().toStringAsFixed(1),
      'rating_count': _random.nextInt(100) + 10,
      'total_sales': _random.nextInt(500) + 50,
    });
  }

  // Generate mock users (drivers)
  static List<Map<String, dynamic>> getMockUsers({int count = 10}) {
    return List.generate(count, (index) => {
      'id': index + 1,
      'name': '${_firstNames[index % _firstNames.length]} ${_lastNames[index % _lastNames.length]}',
      'email': '${_firstNames[index % _firstNames.length].toLowerCase()}.${_lastNames[index % _lastNames.length].toLowerCase()}@goldtaxi.sk',
      'phone': '+421 9${_random.nextInt(90000000) + 10000000}',
      'avatar_url': 'https://i.pravatar.cc/150?u=${index + 1}',
      'roles': ['driver'],
      'first_name': _firstNames[index % _firstNames.length],
      'last_name': _lastNames[index % _lastNames.length],
      'description': '',
      'acf': {
        'car_model': _carModels[index % _carModels.length],
        'car_plate': '${String.fromCharCode(65 + _random.nextInt(26))}${String.fromCharCode(65 + _random.nextInt(26))} ${_random.nextInt(900) + 100}',
        'rating': _randomRating().toStringAsFixed(1),
        'total_rides': _random.nextInt(500) + 50,
        'is_available': _random.nextBool(),
        'location': {
          'lat': 48.1 + (_random.nextDouble() * 0.5 - 0.25),
          'lng': 17.1 + (_random.nextDouble() * 0.5 - 0.25),
        },
      },
      'meta': {
        'rating_count': _random.nextInt(100) + 10,
        'status': _random.nextBool() ? 'online' : 'offline',
      },
    });
  }

  // Generate mock bookings
  static List<Map<String, dynamic>> getMockBookings({int count = 8}) {
    return List.generate(count, (index) => {
      'id': index + 1,
      'customer_id': _random.nextInt(10) + 1,
      'driver_id': _random.nextInt(10) + 1,
      'pickup_location': '${_streets[index % _streets.length]} ${_random.nextInt(100) + 1}, ${_cities[index % _cities.length]}',
      'dropoff_location': '${_streets[_random.nextInt(_streets.length)]} ${_random.nextInt(100) + 1}, ${_cities[_random.nextInt(_cities.length)]}',
      'pickup_date': _randomFutureDate().toIso8601String(),
      'dropoff_date': _randomFutureDate().add(Duration(minutes: _random.nextInt(60) + 15)).toIso8601String(),
      'distance': (_random.nextDouble() * 20 + 1).toStringAsFixed(2),
      'duration': _random.nextInt(60) + 5,
      'price': (_randomPrice() * 10).toStringAsFixed(2),
      'status': const ['confirmed', 'completed', 'cancelled', 'pending'][_random.nextInt(4)],
      'service_type': _services[_random.nextInt(_services.length)],
      'payment_method': const ['cash', 'card', 'online'][_random.nextInt(3)],
      'created_at': _randomDate().toIso8601String(),
      'rating': _random.nextBool() ? _randomRating().toStringAsFixed(1) : null,
      'notes': _random.nextBool() ? 'Čakám na chodníku' : '',
    });
  }

  // Generate mock notifications
  static List<Map<String, dynamic>> getMockNotifications({int count = 5}) {
    final titles = [
      'Nova objednávka',
      'Jazda potvrdená',
      'Vodič je na ceste',
      'Platba potvrdená',
      'Hodnotenie od zákazníka'
    ];
    final messages = [
      'Máte novú objednávku na prevádzku',
      'Vaša objednávka #1000 bola potvrdená',
      'Vodič je na ceste k Vám',
      'Platba vo výške €25.00 bola úspešne spracovaná',
      'Získali ste nové hodnotenie: 4.5 hviezdičiek'
    ];
    final types = ['booking', 'payment', 'rating', 'system'];
    
    return List.generate(count, (index) => {
      'id': index + 1,
      'user_id': _random.nextInt(10) + 1,
      'title': titles[_random.nextInt(titles.length)],
      'message': messages[_random.nextInt(messages.length)],
      'type': types[_random.nextInt(types.length)],
      'is_read': _random.nextBool(),
      'created_at': _randomDate().toIso8601String(),
      'data': {
        'booking_id': index + 1000,
        'amount': (_randomPrice() * 10).toStringAsFixed(2),
      },
    });
  }

  // Generate mock FAQs
  static List<Map<String, dynamic>> getMockFAQs({int count = 6}) {
    return List.generate(count, (index) => {
      'id': index + 1,
      'title': {
        'rendered': const [
          'Ako objednam taxi?',
          'Aké sú platobné metódy?',
          'Môžem zrušiť objednávku?',
          'Ako dlho trvá prijazd vodiča?',
          'Sú vozidlá poistené?',
          'Ako kontaktovať podporu?'
        ][index % 6],
      },
      'content': {
        'rendered': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.'
      },
      'excerpt': {
        'rendered': const [
          'Návod na objednávku taxi',
          'Platobné možnosti',
          'Zrušenie objednávky',
          'Čas prijazdu vodiča',
          'Poistovanie vozidiel',
          'Kontakt na podporu'
        ][index % 6],
      },
      'status': 'publish',
      'menu_order': index + 1,
      'categories': [index % 4 + 1],
    });
  }

  // Generate mock reviews
  static List<Map<String, dynamic>> getMockReviews({int count = 10}) {
    return List.generate(count, (index) => {
      'id': index + 1,
      'post': _random.nextInt(10) + 1,
      'user': _random.nextInt(10) + 1,
      'author_name': '${_firstNames[index % _firstNames.length]} ${_lastNames[index % _lastNames.length]}',
      'author_email': '${_firstNames[index % _firstNames.length].toLowerCase()}.${_lastNames[index % _lastNames.length].toLowerCase()}@example.com',
      'rating': _randomRating(),
      'comment': const [
        'Výborná služba, rýchly príjazd!',
        'Vodič bol veľmi milý a profesionálny',
        'Čisté auto, príjemná jazda',
        'Spokojný zákazník, určite doporučujem',
        'Cena zodpovedá kvalite',
        'Jeďte s Gold-Taxi, nebudete Ľutovať!'
      ][_random.nextInt(6)],
      'date_created': _randomDate().toIso8601String(),
      'approved': true,
    });
  }

  // Generate mock invoices
  static List<Map<String, dynamic>> getMockInvoices({int count = 4}) {
    return List.generate(count, (index) => {
      'id': '${index + 1}',
      'booking_id': '${index + 1000}',
      'user_id': '${_random.nextInt(10) + 1}',
      'amount': (_randomPrice() * 100).toStringAsFixed(2),
      'currency': 'EUR',
      'status': const ['paid', 'pending', 'cancelled'][_random.nextInt(3)],
      'payment_method': const ['card', 'cash', 'bank_transfer'][_random.nextInt(3)],
      'issue_date': _randomDate().toIso8601String(),
      'due_date': _randomFutureDate().toIso8601String(),
      'paid_date': _random.nextBool() ? _randomDate().toIso8601String() : null,
      'items': List.generate(_random.nextInt(3) + 1, (i) => {
        'description': 'Taxi služba ${_services[_random.nextInt(_services.length)]}',
        'quantity': 1,
        'unit_price': (_randomPrice() * 10).toStringAsFixed(2),
        'total': (_randomPrice() * 10).toStringAsFixed(2),
      }),
    });
  }

  // Generate mock services (as ServiceModel compatible)
  static List<Map<String, dynamic>> getMockServices({int count = 6}) {
    return List.generate(count, (index) => {
      'id': index + 1,
      'name': _services[index % _services.length],
      'description': 'Profesionálna taxi služba ${_services[index % _services.length]} pre vaše pohodlie',
      'price': (_randomPrice() * 10).toStringAsFixed(2),
      'category': 'Taxi',
      'provider': _providers[_random.nextInt(_providers.length)],
      'rating': _randomRating(),
      'review_count': _random.nextInt(100) + 10,
      'images': ['https://via.placeholder.com/400x300/FFD700/000000?text=${_services[index % _services.length]}'],
      'duration': '${_random.nextInt(30) + 10}',
      'capacity': '${_random.nextInt(3) + 2}',
      'features': const [
        ['Klíma', 'WiFi', 'Voda'], 
        ['Klíma', 'WiFi', 'Voda', 'USB'], 
        ['Klíma', 'WiFi', 'Voda', 'TV'],
        ['Klíma', 'Eco', 'Voda'],
        ['Veľký kufr', '7-8 osôb'],
        ['Ženská posádka', 'Parfém']
      ][index % 6],
      'is_available': _random.nextBool(),
      'min_capacity': index == 4 ? 6 : 2,
      'max_capacity': index == 4 ? 8 : 4,
    });
  }

  // Generate mock events
  static List<Map<String, dynamic>> getMockEvents({int count = 4}) {
    return List.generate(count, (index) => {
      'id': index + 1,
      'title': {
        'rendered': const [
          'Letné zľavy na letiskové transfery',
          'Novinka: Nočný taxi so zľavou 20%',
          'Akcia: 3 jazdy = 4. zadarmo',
          'Spustenie novej flotele'
        ][index % 4],
      },
      'content': {
        'rendered': 'Pridajte sa k nám a využite výhody! Akcia platí do 31.12.2026'
      },
      'excerpt': {
        'rendered': const [
          'Zľavy na letiskové transfery',
          'Nočný taxi s výhodou',
          'Vernostný program',
          'Nová flota vozidiel'
        ][index % 4],
      },
      'start_date': _randomFutureDate().toIso8601String(),
      'end_date': _randomFutureDate().add(const Duration(days: 7)).toIso8601String(),
      'location': _cities[index % _cities.length],
      'organizer': 'Gold-Taxi',
      'featured_image': 'https://via.placeholder.com/800x400/FFD700/000000?text=Event+${index + 1}',
      'status': 'publish',
    });
  }

  // Get mock user profile
  static Map<String, dynamic> getMockUserProfile() {
    return {
      'id': 1,
      'name': 'Erik Babčan',
      'email': 'erik.babcan@example.com',
      'phone': '+421 905 123 456',
      'avatar': 'https://i.pravatar.cc/150?u=erik',
      'roles': ['customer'],
      'balance': (_randomPrice() * 100).toStringAsFixed(2),
      'total_rides': _random.nextInt(50) + 10,
      'rating': _randomRating().toStringAsFixed(1),
      'loyalty_points': _random.nextInt(1000) + 100,
      'preferred_service': _services[_random.nextInt(_services.length)],
      'addresses': [
        {
          'id': 1,
          'label': 'Domov',
          'address': '${_streets[_random.nextInt(_streets.length)]} ${_random.nextInt(50) + 1}, ${_cities[_random.nextInt(_cities.length)]}',
          'lat': 48.1486,
          'lng': 17.1077,
          'is_default': true,
        },
        {
          'id': 2,
          'label': 'Práca',
          'address': '${_streets[_random.nextInt(_streets.length)]} ${_random.nextInt(50) + 1}, ${_cities[_random.nextInt(_cities.length)]}',
          'lat': 48.1492,
          'lng': 17.1085,
          'is_default': false,
        },
      ],
    };
  }

  // Get app statistics
  static Map<String, dynamic> getMockStats() {
    return {
      'total_bookings': _random.nextInt(1000) + 500,
      'completed_bookings': _random.nextInt(800) + 400,
      'active_drivers': _random.nextInt(50) + 20,
      'total_users': _random.nextInt(5000) + 1000,
      'daily_bookings': _random.nextInt(100) + 30,
      'average_rating': ((_randomRating() + 4.0) / 2).toStringAsFixed(1),
      'revenue_today': (_randomPrice() * 1000).toStringAsFixed(2),
    };
  }

  // Get live driver positions (for map)
  static List<Map<String, dynamic>> getMockDriverPositions() {
    return List.generate(10, (index) => {
      'driverId': index + 1,
      'name': '${_firstNames[index % _firstNames.length]} ${_lastNames[index % _lastNames.length]}',
      'lat': 48.1486 + (_random.nextDouble() * 0.1 - 0.05),
      'lng': 17.1077 + (_random.nextDouble() * 0.1 - 0.05),
      'bearing': _random.nextDouble() * 360,
      'isAvailable': _random.nextBool(),
      'carModel': _carModels[index % _carModels.length],
      'rating': _randomRating().toStringAsFixed(1),
      'serviceType': _services[_random.nextInt(_services.length)],
    });
  }
}

