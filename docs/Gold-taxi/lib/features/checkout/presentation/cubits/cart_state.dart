import 'package:equatable/equatable.dart';
import 'package:gold_taxi/models/cart_item_model.dart';

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoaded extends CartState {
  final List<CartItemModel> items;

  const CartLoaded({required this.items});

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get vat => subtotal * 0.20; // 20% VAT
  double get total => subtotal + vat;

  @override
  List<Object?> get props => [items];
}
