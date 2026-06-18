import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/reviews_repository.dart';
import 'reviews_event.dart';
import 'reviews_state.dart';

class ReviewsBloc extends Bloc<ReviewsEvent, ReviewsState> {
  final ReviewsRepository _reviewsRepository;

  ReviewsBloc(this._reviewsRepository) : super(ReviewsInitial()) {
    on<FetchReviews>(_onFetchReviews);
    on<SubmitReview>(_onSubmitReview);
  }

  Future<void> _onFetchReviews(
    FetchReviews event,
    Emitter<ReviewsState> emit,
  ) async {
    emit(ReviewsLoading());
    try {
      final reviews = await _reviewsRepository.getReviews(event.postId);
      emit(ReviewsLoaded(reviews));
    } catch (e) {
      emit(ReviewsError(e.toString()));
    }
  }

  Future<void> _onSubmitReview(
    SubmitReview event,
    Emitter<ReviewsState> emit,
  ) async {
    emit(ReviewSubmissionInProgress());
    try {
      final newReview = await _reviewsRepository.submitReview(
        postId: event.postId,
        authorName: event.authorName,
        authorEmail: event.authorEmail,
        rating: event.rating,
        comment: event.comment,
      );
      emit(ReviewSubmissionSuccess(newReview));
    } catch (e) {
      emit(ReviewSubmissionFailure(e.toString()));
    }
  }
}
