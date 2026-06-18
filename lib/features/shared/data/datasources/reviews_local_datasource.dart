import 'package:hive_flutter/hive_flutter.dart';
import 'package:gold_taxi/models/review_model.dart';

class ReviewsLocalDataSource {
  static const String _boxName = 'reviews_cache_box';

  /// Cache reviews for a specific post
  Future<void> cacheReviews(int postId, List<ReviewModel> reviews) async {
    final box = await Hive.openBox(_boxName);
    final reviewsJson = reviews.map((review) => review.toJson()).toList();
    await box.put('reviews_$postId', reviewsJson);
  }

  /// Get cached reviews for a specific post
  Future<List<ReviewModel>> getCachedReviews(int postId) async {
    final box = await Hive.openBox(_boxName);
    final reviewsJson = box.get('reviews_$postId') as List?;
    if (reviewsJson != null) {
      return reviewsJson
          .map(
            (json) =>
                ReviewModel.fromJson(Map<String, dynamic>.from(json as Map)),
          )
          .toList();
    }
    return [];
  }
}
