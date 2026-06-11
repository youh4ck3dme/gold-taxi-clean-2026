import 'package:equatable/equatable.dart';
import 'package:gold_taxi/models/product_model.dart';

class CartItemModel extends Equatable {
  final ProductModel product;
  final int quantity;
  final String? selectedVariation;

  const CartItemModel({
    required this.product,
    this.quantity = 1,
    this.selectedVariation,
  });

  double get totalPrice => product.price * quantity;

  CartItemModel copyWith({
    ProductModel? product,
    int? quantity,
    String? selectedVariation,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedVariation: selectedVariation ?? this.selectedVariation,
    );
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int? ?? 1,
      selectedVariation: json['selected_variation'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'quantity': quantity,
    'selected_variation': selectedVariation,
  };

  @override
  List<Object?> get props => [product, quantity, selectedVariation];
}
