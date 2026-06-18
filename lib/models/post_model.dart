import 'package:equatable/equatable.dart';

class PostModel extends Equatable {
  final String id;
  final DateTime date;
  final String title;
  final String content;
  final String excerpt;
  final String? featuredImageUrl;
  final String? authorName;
  final List<String> categories;
  final List<String> tags;

  const PostModel({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    required this.excerpt,
    this.featuredImageUrl,
    this.authorName,
    this.categories = const [],
    this.tags = const [],
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    // Original WordPress Parser
    String parseRendered(dynamic data) {
      if (data is Map) return data['rendered'] as String? ?? '';
      return data?.toString() ?? '';
    }

    return PostModel(
      id: json['id']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      title: parseRendered(json['title']),
      content: parseRendered(json['content']),
      excerpt: parseRendered(json['excerpt']),
      featuredImageUrl: _getWpFeaturedImage(json),
      authorName: _getWpAuthorName(json),
      categories: [], // Simplified for now
      tags: [],
    );
  }

  factory PostModel.fromSupabaseJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String? ?? '',
      date: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      excerpt: json['excerpt'] as String? ?? '',
      featuredImageUrl: json['featured_image_url'] as String?,
      authorName: json['author_name'] as String?, // Assuming join or flat field
      categories: [if (json['category'] != null) json['category'] as String],
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  static String? _getWpFeaturedImage(Map<String, dynamic> json) {
    try {
      return json['_embedded']?['wp:featuredmedia']?[0]?['source_url'] as String?;
    } catch (_) {
      return null;
    }
  }

  static String? _getWpAuthorName(Map<String, dynamic> json) {
    try {
      return json['_embedded']?['author']?[0]?['name'] as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [id, date, title, content, excerpt, featuredImageUrl, authorName, categories, tags];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'title': title,
      'content': content,
      'excerpt': excerpt,
      'featured_image_url': featuredImageUrl,
      'author_name': authorName,
      'categories': categories,
      'tags': tags,
    };
  }
}
