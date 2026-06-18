import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

abstract class BaseWordPressModel extends Equatable {
  @JsonKey(name: 'id')
  final int id;

  @JsonKey(name: 'date', fromJson: parseDate)
  final DateTime date;

  @JsonKey(name: 'title', fromJson: parseRendered)
  final String title;

  @JsonKey(name: 'content', fromJson: parseRendered)
  final String content;

  @JsonKey(name: 'excerpt', fromJson: parseRendered)
  final String excerpt;

  @JsonKey(name: '_embedded')
  final Map<String, dynamic>? embedded;

  const BaseWordPressModel({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    required this.excerpt,
    this.embedded,
  });

  // Resilient parsing helpers
  static String parseRendered(dynamic json) {
    if (json is Map) {
      return json['rendered'] as String? ?? '';
    }
    return json?.toString() ?? '';
  }

  static DateTime parseDate(dynamic json) {
    if (json is String) {
      return DateTime.tryParse(json) ?? DateTime.now();
    }
    return DateTime.now();
  }

  // Getter for backwards compatibility with UI
  String? get featuredImageUrl => getFeaturedImageUrl();

  // Safe helper methods for _embedded extraction
  String? getAuthorName() {
    try {
      final authorData = embedded?['author']?[0];
      return authorData?['name'] as String?;
    } catch (_) {
      return null;
    }
  }

  List<String> getCategoriesList() {
    try {
      final terms = embedded?['wp:term'] as List?;
      if (terms == null) return [];

      for (var termGroup in terms) {
        if (termGroup is List && termGroup.isNotEmpty) {
          final first = termGroup[0];
          if (first is Map && first['taxonomy'] == 'category') {
            return termGroup
                .map((cat) {
                  if (cat is Map) {
                    return cat['name'] as String? ?? '';
                  }
                  return '';
                })
                .where((name) => name.isNotEmpty)
                .toList();
          }
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  String? getFeaturedImageUrl() {
    try {
      return embedded?['wp:featuredmedia']?[0]?['source_url'] as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [id, date, title, content, excerpt, embedded];
}
