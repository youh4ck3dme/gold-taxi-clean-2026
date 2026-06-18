import 'package:hive_flutter/hive_flutter.dart';
import 'package:gold_taxi/models/post_model.dart';

class BlogLocalDataSource {
  static const String _boxName = 'blog_posts_box';

  /// Cache posts locally
  Future<void> cachePosts(List<PostModel> posts) async {
    final box = await Hive.openBox(_boxName);
    final postsJson = posts.map((post) => post.toJson()).toList();
    await box.put('cached_posts', postsJson);
  }

  /// Get cached posts
  Future<List<PostModel>> getCachedPosts() async {
    final box = await Hive.openBox(_boxName);
    final postsJson = box.get('cached_posts') as List?;
    if (postsJson != null) {
      return postsJson
          .map(
            (json) =>
                PostModel.fromJson(Map<String, dynamic>.from(json as Map)),
          )
          .toList();
    }
    return [];
  }
}
