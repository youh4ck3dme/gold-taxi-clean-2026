import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:gold_taxi/models/product_model.dart';
import '../datasources/products_local_datasource.dart';
import '../datasources/products_remote_datasource.dart';

class ProductsRepository {
  final ProductsRemoteDataSource _remoteDataSource;
  final ProductsLocalDataSource _localDataSource;
  final Connectivity _connectivity;

  ProductsRepository(
    this._remoteDataSource,
    this._localDataSource,
    this._connectivity,
  );

  /// Fetch products from remote API or fallback to local cache
  Future<List<ProductModel>> getProducts({
    int page = 1,
    int perPage = 10,
    String? search,
  }) async {
    final connectivityResult = await _connectivity.checkConnectivity();
    final isOnline = !connectivityResult.contains(ConnectivityResult.none);

    if (isOnline) {
      try {
        final products = await _remoteDataSource.fetchProducts(
          page: page,
          perPage: perPage,
          search: search,
        );
        if (page == 1 && (search == null || search.isEmpty)) {
          await _localDataSource.cacheProducts(products);
        }
        return products;
      } catch (_) {
        if (page == 1 && (search == null || search.isEmpty)) {
          return await _localDataSource.getCachedProducts();
        }
        rethrow;
      }
    } else {
      if (page == 1 && (search == null || search.isEmpty)) {
        return await _localDataSource.getCachedProducts();
      }
      return [];
    }
  }
}
