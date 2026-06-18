import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gold_taxi/models/post_model.dart';

class BlogRemoteDataSource {
  final SupabaseClient _supabase;

  BlogRemoteDataSource(SupabaseClient supabase) : _supabase = supabase;

  /// Fetch posts from Supabase
  Future<List<PostModel>> fetchPosts({int page = 1, int perPage = 10, String? search}) async {
    final from = (page - 1) * perPage;
    final to = from + perPage - 1;

    var query = _supabase.from('posts').select();

    if (search != null && search.isNotEmpty) {
      query = query.ilike('title', '%$search%');
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(from, to);

    return response.map((json) => PostModel.fromSupabaseJson(json)).toList();
  }
}

