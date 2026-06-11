import 'package:equatable/equatable.dart';

/// Service Model (JetEngine Services)
class ServiceModel extends Equatable {
  final int id;
  final String name;
  final String description;
  final double price;
  final String category;
  final List<String> images;
  final String provider;
  final double rating;
  final int reviewCount;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.images = const [],
    required this.provider,
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    String parsedName = '';
    if (json['name'] is String) {
      parsedName = json['name'] as String;
    } else if (json['title'] is Map) {
      parsedName = json['title']['rendered'] as String? ?? '';
    } else if (json['title'] is String) {
      parsedName = json['title'] as String;
    } else {
      parsedName = '';
    }

    String parsedDescription = '';
    if (json['description'] is String) {
      parsedDescription = json['description'] as String;
    } else if (json['content'] is Map) {
      parsedDescription = json['content']['rendered'] as String? ?? '';
    } else {
      parsedDescription = '';
    }

    return ServiceModel(
      id: json['id'] as int? ?? 0,
      name: parsedName,
      description: parsedDescription,
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      category: json['category'] as String? ?? '',
      images: _getImages(json['images']),
      provider: json['provider'] as String? ?? '',
      rating: double.tryParse(json['rating'].toString()) ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price.toString(),
    'category': category,
    'provider': provider,
    'rating': rating.toString(),
    'review_count': reviewCount,
    'images': images,
  };

  static List<String> _getImages(dynamic images) {
    if (images is List) {
      return images
          .map((img) => img is String ? img : img['url'] as String? ?? '')
          .toList()
          .where((url) => url.isNotEmpty)
          .toList();
    }
    return [];
  }

  @override
  List<Object?> get props => [id, name, price, category, provider];
}
