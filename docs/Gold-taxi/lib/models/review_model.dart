import 'package:equatable/equatable.dart';

class ReviewModel extends Equatable {
  final int id;
  final String authorName;
  final String? authorEmail;
  final int rating;
  final String comment;
  final DateTime date;
  final int postId;

  const ReviewModel({
    required this.id,
    required this.authorName,
    this.authorEmail,
    required this.rating,
    required this.comment,
    required this.date,
    required this.postId,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as int? ?? 0,
      authorName: json['author_name'] as String? ?? 'Anonym',
      authorEmail: json['author_email'] as String?,
      rating: int.tryParse(json['rating'].toString()) ?? 5,
      comment: json['comment'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      postId: json['post_id'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'author_name': authorName,
    'author_email': authorEmail,
    'rating': rating,
    'comment': comment,
    'date': date.toIso8601String(),
    'post_id': postId,
  };

  @override
  List<Object?> get props => [id, authorName, rating, comment, date, postId];
}
