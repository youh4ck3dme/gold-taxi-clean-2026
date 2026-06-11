import 'package:gold_taxi/core/services/api_service.dart';
import 'package:gold_taxi/models/post_model.dart';

class BlogRemoteDataSource {
  final ApiService _apiService;

  BlogRemoteDataSource(this._apiService);

  /// Fetch posts from WordPress REST API
  Future<List<PostModel>> fetchPosts({int page = 1, int perPage = 10, String? search}) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'per_page': perPage,
      '_embed': 1,
    };
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final response = await _apiService.get(
      '/wp-json/wp/v2/posts',
      queryParameters: queryParams,
    );

    if (response is List) {
      return response.map((json) => PostModel.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
