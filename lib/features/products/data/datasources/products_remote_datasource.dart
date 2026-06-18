import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gold_taxi/models/product_model.dart';

class ProductsRemoteDataSource {
  final SupabaseClient _supabase;

  ProductsRemoteDataSource(SupabaseClient supabase) : _supabase = supabase;

  /// Fetch products from Supabase
  Future<List<ProductModel>> fetchProducts({int page = 1, int perPage = 10, String? search}) async {
    final from = (page - 1) * perPage;
    final to = from + perPage - 1;

    var query = _supabase.from('products').select();

    if (search != null && search.isNotEmpty) {
      query = query.ilike('name', '%$search%');
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(from, to);

    return response.map((json) => ProductModel.fromSupabaseJson(json)).toList();
  }
}
