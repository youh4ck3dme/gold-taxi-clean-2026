import 'package:equatable/equatable.dart';
import 'package:gold_taxi/models/review_model.dart';

abstract class ReviewsState extends Equatable {
  const ReviewsState();

  @override
  List<Object?> get props => [];
}

class ReviewsInitial extends ReviewsState {}

class ReviewsLoading extends ReviewsState {}

class ReviewsLoaded extends ReviewsState {
  final List<ReviewModel> reviews;

  const ReviewsLoaded(this.reviews);

  @override
  List<Object?> get props => [reviews];
}

class ReviewsError extends ReviewsState {
  final String message;

  const ReviewsError(this.message);

  @override
  List<Object?> get props => [message];
}

class ReviewSubmissionInProgress extends ReviewsState {}

class ReviewSubmissionSuccess extends ReviewsState {
  final ReviewModel newReview;

  const ReviewSubmissionSuccess(this.newReview);

  @override
  List<Object?> get props => [newReview];
}

class ReviewSubmissionFailure extends ReviewsState {
  final String message;

  const ReviewSubmissionFailure(this.message);

  @override
  List<Object?> get props => [message];
}
