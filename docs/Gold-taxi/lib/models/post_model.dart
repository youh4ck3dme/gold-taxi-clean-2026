import 'package:json_annotation/json_annotation.dart';
import 'base_wordpress_model.dart';

part 'post_model.g.dart';

@JsonSerializable()
class PostModel extends BaseWordPressModel {
  @JsonKey(name: 'slug')
  final String slug;

  @JsonKey(name: 'author')
  final int authorId;

  @JsonKey(name: 'categories', defaultValue: [])
  final List<int> categoryIds;

  @JsonKey(name: 'tags', defaultValue: [])
  final List<int> tagIds;

  const PostModel({
    required super.id,
    required super.date,
    required super.title,
    required super.content,
    required super.excerpt,
    super.embedded,
    required this.slug,
    required this.authorId,
    required this.categoryIds,
    required this.tagIds,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) => _$PostModelFromJson(json);

  Map<String, dynamic> toJson() => _$PostModelToJson(this);

  @override
  List<Object?> get props => [...super.props, slug, authorId, categoryIds, tagIds];
}
