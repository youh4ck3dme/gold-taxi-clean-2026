import 'package:json_annotation/json_annotation.dart';
import 'base_wordpress_model.dart';

part 'event_model.g.dart';

@JsonSerializable()
class EventModel extends BaseWordPressModel {
  @JsonKey(name: 'start_date', fromJson: _parseDate)
  final DateTime startDate;

  @JsonKey(name: 'end_date', fromJson: _parseDate)
  final DateTime endDate;

  @JsonKey(name: 'location')
  final String? location;

  @JsonKey(name: 'latitude', fromJson: _parseDouble)
  final double? latitude;

  @JsonKey(name: 'longitude', fromJson: _parseDouble)
  final double? longitude;

  @JsonKey(name: 'category')
  final String category;

  @JsonKey(name: 'images', fromJson: _parseImages)
  final List<String> images;

  @JsonKey(name: 'price', fromJson: _parseDouble)
  final double? price;

  const EventModel({
    required super.id,
    required super.date,
    required super.title,
    required super.content,
    super.excerpt = '',
    super.embedded,
    required this.startDate,
    required this.endDate,
    this.location,
    this.latitude,
    this.longitude,
    required this.category,
    this.images = const [],
    this.price,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) => _$EventModelFromJson(json);

  Map<String, dynamic> toJson() => _$EventModelToJson(this);

  // Getter for backwards compatibility with UI
  String get description => content;

  static DateTime _parseDate(dynamic json) {
    if (json is String) {
      return DateTime.tryParse(json) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static double? _parseDouble(dynamic json) {
    if (json == null) return null;
    return double.tryParse(json.toString());
  }

  static List<String> _parseImages(dynamic json) {
    if (json is List) {
      return json
          .map((img) => img is String ? img : img['url'] as String? ?? '')
          .toList()
          .where((url) => url.isNotEmpty)
          .toList();
    }
    return [];
  }

  @override
  List<Object?> get props => [...super.props, startDate, endDate, location, category, images, price];
}
