// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostModel _$PostModelFromJson(Map<String, dynamic> json) => PostModel(
  id: (json['id'] as num).toInt(),
  date: BaseWordPressModel.parseDate(json['date']),
  title: BaseWordPressModel.parseRendered(json['title']),
  content: BaseWordPressModel.parseRendered(json['content']),
  excerpt: BaseWordPressModel.parseRendered(json['excerpt']),
  embedded: json['_embedded'] as Map<String, dynamic>?,
  slug: json['slug'] as String,
  authorId: (json['author'] as num).toInt(),
  categoryIds:
      (json['categories'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      [],
  tagIds:
      (json['tags'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      [],
);

Map<String, dynamic> _$PostModelToJson(PostModel instance) => <String, dynamic>{
  'id': instance.id,
  'date': instance.date.toIso8601String(),
  'title': instance.title,
  'content': instance.content,
  'excerpt': instance.excerpt,
  '_embedded': instance.embedded,
  'slug': instance.slug,
  'author': instance.authorId,
  'categories': instance.categoryIds,
  'tags': instance.tagIds,
};
