import 'package:equatable/equatable.dart';

/// Product Model (WooCommerce or Supabase)
class ProductModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? salePrice;
  final String? sku;
  final int? stock;
  final List<String> images;
  final List<String> categories;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.salePrice,
    this.sku,
    this.stock,
    this.images = const [],
    this.categories = const [],
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      salePrice: double.tryParse(json['sale_price']?.toString() ?? '') ?? 0.0,
      sku: json['sku'] as String? ?? '',
      stock: json['stock_quantity'] as int? ?? 0,
      images: _getWpImages(json['images']),
      categories: _getWpCategories(json['categories']),
    );
  }

  factory ProductModel.fromSupabaseJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num? ?? 0.0).toDouble(),
      salePrice: (json['sale_price'] as num? ?? 0.0).toDouble(),
      sku: json['sku'] as String?,
      stock: json['stock'] as int?,
      images: [if (json['image_url'] != null) json['image_url'] as String],
      categories: [if (json['category'] != null) json['category'] as String],
    );
  }

  static List<String> _getWpImages(dynamic images) {
    if (images is List) {
      return images
          .map((img) => img['src'] as String? ?? '')
          .toList()
          .where((url) => url.isNotEmpty)
          .toList();
    }
    return [];
  }

  static List<String> _getWpCategories(dynamic categories) {
    if (categories is List) {
      return categories
          .map((cat) => cat['name'] as String? ?? '')
          .toList();
    }
    return [];
  }

  @override
  List<Object?> get props => [id, name, price, sku, stock];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'sale_price': salePrice,
      'sku': sku,
      'stock_quantity': stock,
      'images': images.map((img) => {'src': img}).toList(),
      'categories': categories.map((cat) => {'name': cat}).toList(),
    };
  }
}
