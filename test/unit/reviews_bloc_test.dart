import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gold_taxi/features/shared/presentation/bloc/reviews_bloc.dart';
import 'package:gold_taxi/features/shared/presentation/bloc/reviews_event.dart';
import 'package:gold_taxi/features/shared/presentation/bloc/reviews_state.dart';
import 'package:gold_taxi/features/shared/data/repositories/reviews_repository.dart';
import 'package:gold_taxi/models/review_model.dart';

class MockReviewsRepository extends Mock implements ReviewsRepository {}

void main() {
  late ReviewsBloc reviewsBloc;
  late MockReviewsRepository mockReviewsRepository;

  setUp(() {
    mockReviewsRepository = MockReviewsRepository();
    reviewsBloc = ReviewsBloc(mockReviewsRepository);
  });

  tearDown(() {
    reviewsBloc.close();
  });

  group('ReviewsBloc Tests', () {
    final testReview = ReviewModel(
      id: 1,
      authorName: 'Jozef Mrkvicka',
      authorEmail: 'jozef@mrkvicka.com',
      rating: 5,
      comment: 'Super taxi!',
      date: DateTime(2026, 6, 11),
      postId: 101,
    );

    test('Initial state is ReviewsInitial', () {
      expect(reviewsBloc.state, isA<ReviewsInitial>());
    });

    test('FetchReviews emits [ReviewsLoading, ReviewsLoaded] when repository succeeds', () async {
      when(() => mockReviewsRepository.getReviews(any()))
          .thenAnswer((_) async => [testReview]);

      expectLater(
        reviewsBloc.stream,
        emitsInOrder([
          isA<ReviewsLoading>(),
          isA<ReviewsLoaded>(),
        ]),
      );

      reviewsBloc.add(const FetchReviews(101));
    });

    test('FetchReviews emits [ReviewsLoading, ReviewsError] when repository throws error', () async {
      when(() => mockReviewsRepository.getReviews(any()))
          .thenThrow(Exception('API error'));

      expectLater(
        reviewsBloc.stream,
        emitsInOrder([
          isA<ReviewsLoading>(),
          isA<ReviewsError>(),
        ]),
      );

      reviewsBloc.add(const FetchReviews(101));
    });

    test('SubmitReview emits [ReviewSubmissionInProgress, ReviewSubmissionSuccess] when repository succeeds', () async {
      when(() => mockReviewsRepository.submitReview(
            postId: any(named: 'postId'),
            authorName: any(named: 'authorName'),
            authorEmail: any(named: 'authorEmail'),
            rating: any(named: 'rating'),
            comment: any(named: 'comment'),
          )).thenAnswer((_) async => testReview);

      expectLater(
        reviewsBloc.stream,
        emitsInOrder([
          isA<ReviewSubmissionInProgress>(),
          isA<ReviewSubmissionSuccess>(),
        ]),
      );

      reviewsBloc.add(const SubmitReview(
        postId: 101,
        authorName: 'Jozef Mrkvicka',
        authorEmail: 'jozef@mrkvicka.com',
        rating: 5,
        comment: 'Super taxi!',
      ));
    });

    test('SubmitReview emits [ReviewSubmissionInProgress, ReviewSubmissionFailure] when repository fails', () async {
      when(() => mockReviewsRepository.submitReview(
            postId: any(named: 'postId'),
            authorName: any(named: 'authorName'),
            authorEmail: any(named: 'authorEmail'),
            rating: any(named: 'rating'),
            comment: any(named: 'comment'),
          )).thenThrow(Exception('Submission failed'));

      expectLater(
        reviewsBloc.stream,
        emitsInOrder([
          isA<ReviewSubmissionInProgress>(),
          isA<ReviewSubmissionFailure>(),
        ]),
      );

      reviewsBloc.add(const SubmitReview(
        postId: 101,
        authorName: 'Jozef Mrkvicka',
        authorEmail: 'jozef@mrkvicka.com',
        rating: 5,
        comment: 'Super taxi!',
      ));
    });
  });
}
