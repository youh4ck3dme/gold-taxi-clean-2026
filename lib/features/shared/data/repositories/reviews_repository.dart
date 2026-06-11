import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:gold_taxi/models/review_model.dart';
import '../datasources/reviews_local_datasource.dart';
import '../datasources/reviews_remote_datasource.dart';

class ReviewsRepository {
  final ReviewsRemoteDataSource _remoteDataSource;
  final ReviewsLocalDataSource _localDataSource;
  final Connectivity _connectivity;

  ReviewsRepository(
    this._remoteDataSource,
    this._localDataSource,
    this._connectivity,
  );

  /// Fetch reviews from remote API or fallback to local cache
  Future<List<ReviewModel>> getReviews(int postId) async {
    final connectivityResult = await _connectivity.checkConnectivity();
    final isOnline = connectivityResult != ConnectivityResult.none;

    if (isOnline) {
      try {
        final reviews = await _remoteDataSource.fetchReviews(postId);
        await _localDataSource.cacheReviews(postId, reviews);
        return reviews;
      } catch (_) {
        return await _localDataSource.getCachedReviews(postId);
      }
    } else {
      return await _localDataSource.getCachedReviews(postId);
    }
  }

  /// Submit a new review (online only, or can fail if offline)
  Future<ReviewModel> submitReview({
    required int postId,
    required String authorName,
    required String authorEmail,
    required int rating,
    required String comment,
  }) async {
    final review = await _remoteDataSource.submitReview(
      postId: postId,
      authorName: authorName,
      authorEmail: authorEmail,
      rating: rating,
      comment: comment,
    );

    // Refresh local cache after successful submission
    final currentReviews = await _localDataSource.getCachedReviews(postId);
    currentReviews.insert(0, review);
    await _localDataSource.cacheReviews(postId, currentReviews);

    return review;
  }
}
