import 'package:equatable/equatable.dart';

/// Event Model (JetEngine Events)
class EventModel extends Equatable {
  final int id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String category;
  final List<String> images;
  final double? price;

  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    this.location,
    this.latitude,
    this.longitude,
    required this.category,
    this.images = const [],
    this.price,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      startDate: DateTime.tryParse(json['start_date'] as String? ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['end_date'] as String? ?? '') ?? DateTime.now(),
      location: json['location'] as String?,
      latitude: double.tryParse(json['latitude'].toString()),
      longitude: double.tryParse(json['longitude'].toString()),
      category: json['category'] as String? ?? '',
      images: _getImages(json['images']),
      price: double.tryParse(json['price'].toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate.toIso8601String(),
    'location': location,
    'latitude': latitude,
    'longitude': longitude,
    'category': category,
    'price': price?.toString(),
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
  List<Object?> get props => [id, title, startDate, endDate, category];
}
