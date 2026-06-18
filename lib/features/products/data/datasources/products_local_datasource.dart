import 'package:hive_flutter/hive_flutter.dart';
import 'package:gold_taxi/models/product_model.dart';

class ProductsLocalDataSource {
  static const String _boxName = 'products_posts_box';

  /// Cache products locally
  Future<void> cacheProducts(List<ProductModel> products) async {
    final box = await Hive.openBox(_boxName);
    final productsJson = products.map((product) => product.toJson()).toList();
    await box.put('cached_products', productsJson);
  }

  /// Get cached products
  Future<List<ProductModel>> getCachedProducts() async {
    final box = await Hive.openBox(_boxName);
    final productsJson = box.get('cached_products') as List?;
    if (productsJson != null) {
      return productsJson
          .map(
            (json) =>
                ProductModel.fromJson(Map<String, dynamic>.from(json as Map)),
          )
          .toList();
    }
    return [];
  }
}
