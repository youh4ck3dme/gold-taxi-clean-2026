import 'package:equatable/equatable.dart';

abstract class ReviewsEvent extends Equatable {
  const ReviewsEvent();

  @override
  List<Object?> get props => [];
}

class FetchReviews extends ReviewsEvent {
  final int postId;

  const FetchReviews(this.postId);

  @override
  List<Object?> get props => [postId];
}

class SubmitReview extends ReviewsEvent {
  final int postId;
  final String authorName;
  final String authorEmail;
  final int rating;
  final String comment;

  const SubmitReview({
    required this.postId,
    required this.authorName,
    required this.authorEmail,
    required this.rating,
    required this.comment,
  });

  @override
  List<Object?> get props => [postId, authorName, authorEmail, rating, comment];
}
