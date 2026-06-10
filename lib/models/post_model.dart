import 'package:equatable/equatable.dart';

/// Post Model (Blog Posts)
class PostModel extends Equatable {
  final int id;
  final String title;
  final String content;
  final String excerpt;
  final String? featuredImageUrl;
  final String slug;
  final DateTime date;
  final int authorId;
  final List<int> categoryIds;
  final List<int> tagIds;

  const PostModel({
    required this.id,
    required this.title,
    required this.content,
    required this.excerpt,
    this.featuredImageUrl,
    required this.slug,
    required this.date,
    required this.authorId,
    this.categoryIds = const [],
    this.tagIds = const [],
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as int? ?? 0,
      title: json['title']?['rendered'] as String? ?? '',
      content: json['content']?['rendered'] as String? ?? '',
      excerpt: json['excerpt']?['rendered'] as String? ?? '',
      featuredImageUrl: _getFeaturedImage(json),
      slug: json['slug'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      authorId: json['author'] as int? ?? 0,
      categoryIds: _getCategoryIds(json['categories']),
      tagIds: _getTagIds(json['tags']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': {'rendered': title},
    'content': {'rendered': content},
    'excerpt': {'rendered': excerpt},
    'slug': slug,
    'date': date.toIso8601String(),
    'author': authorId,
    'categories': categoryIds,
    'tags': tagIds,
  };

  static String? _getFeaturedImage(Map<String, dynamic> json) {
    try {
      return json['_embedded']?['wp:featuredmedia']?[0]?['source_url'] as String?;
    } catch (e) {
      return null;
    }
  }

  static List<int> _getCategoryIds(dynamic categories) {
    if (categories is List) {
      return categories.cast<int>();
    }
    return [];
  }

  static List<int> _getTagIds(dynamic tags) {
    if (tags is List) {
      return tags.cast<int>();
    }
    return [];
  }

  @override
  List<Object?> get props => [id, title, slug, date, authorId];
}
