import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../models/post_model.dart';
import '../datasources/local/blog_local_datasource.dart';
import '../datasources/remote/blog_remote_datasource.dart';

class BlogRepository {
  final BlogRemoteDataSource _remoteDataSource;
  final BlogLocalDataSource _localDataSource;
  final Connectivity _connectivity;

  BlogRepository(this._remoteDataSource, this._localDataSource, this._connectivity);

  /// Get posts. Attempts network fetch, falls back to cache on failure/offline.
  Future<List<PostModel>> getPosts({int page = 1, int perPage = 10, String? search}) async {
    final connectivityResult = await _connectivity.checkConnectivity();
    final isOnline = !connectivityResult.contains(ConnectivityResult.none);

    if (isOnline) {
      try {
        final posts = await _remoteDataSource.fetchPosts(
          page: page,
          perPage: perPage,
          search: search,
        );
        // Only cache the first page of default search for offline access
        if (page == 1 && (search == null || search.isEmpty)) {
          await _localDataSource.cachePosts(posts);
        }
        return posts;
      } catch (_) {
        // Fallback to cache if request fails
        if (page == 1 && (search == null || search.isEmpty)) {
          return await _localDataSource.getCachedPosts();
        }
        rethrow;
      }
    } else {
      // Offline mode
      if (page == 1 && (search == null || search.isEmpty)) {
        return await _localDataSource.getCachedPosts();
      }
      return [];
    }
  }
}
