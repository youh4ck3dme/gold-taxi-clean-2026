import 'package:equatable/equatable.dart';

/// Product Model (WooCommerce Products)
class ProductModel extends Equatable {
  final int id;
  final String name;
  final String description;
  final double price;
  final double salePrice;
  final String sku;
  final int stock;
  final List<String> images;
  final List<String> categories;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.salePrice,
    required this.sku,
    required this.stock,
    this.images = const [],
    this.categories = const [],
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      salePrice: double.tryParse(json['sale_price'].toString()) ?? 0.0,
      sku: json['sku'] as String? ?? '',
      stock: json['stock_quantity'] as int? ?? 0,
      images: _getImages(json['images']),
      categories: _getCategories(json['categories']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price.toString(),
    'sale_price': salePrice.toString(),
    'sku': sku,
    'stock_quantity': stock,
  };

  static List<String> _getImages(dynamic images) {
    if (images is List) {
      return images
          .map((img) => img['src'] as String? ?? '')
          .toList()
          .where((url) => url.isNotEmpty)
          .toList();
    }
    return [];
  }

  static List<String> _getCategories(dynamic categories) {
    if (categories is List) {
      return categories
          .map((cat) => cat['name'] as String? ?? '')
          .toList();
    }
    return [];
  }

  @override
  List<Object?> get props => [id, name, price, sku, stock];
}
