import 'package:gold_taxi/core/services/api_service.dart';
import 'package:gold_taxi/models/product_model.dart';

class ProductsRemoteDataSource {
  final ApiService _apiService;

  ProductsRemoteDataSource(this._apiService);

  /// Fetch products from WooCommerce API
  Future<List<ProductModel>> fetchProducts({int page = 1, int perPage = 10, String? search}) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'per_page': perPage,
    };
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final response = await _apiService.get(
      '/wp-json/wc/v3/products',
      queryParameters: queryParams,
    );

    if (response is List) {
      return response.map((json) => ProductModel.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
