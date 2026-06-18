import 'package:gold_taxi/core/constants/api_constants.dart';
import 'package:gold_taxi/core/services/api_service.dart';
import 'package:gold_taxi/models/review_model.dart';

class ReviewsRemoteDataSource {
  final ApiService _apiService;

  ReviewsRemoteDataSource(this._apiService);

  /// Fetch reviews for a specific post/product/service/event
  Future<List<ReviewModel>> fetchReviews(int postId) async {
    final response = await _apiService.get(
      ApiConstants.reviewsEndpoint,
      queryParameters: {'post_id': postId},
    );

    if (response is List) {
      return response
          .map((json) => ReviewModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Submit a new review
  Future<ReviewModel> submitReview({
    required int postId,
    required String authorName,
    required String authorEmail,
    required int rating,
    required String comment,
  }) async {
    final response = await _apiService.post(
      ApiConstants.reviewsEndpoint,
      data: {
        'post_id': postId,
        'author_name': authorName,
        'author_email': authorEmail,
        'rating': rating,
        'comment': comment,
      },
    );

    return ReviewModel.fromJson(response as Map<String, dynamic>);
  }
}
