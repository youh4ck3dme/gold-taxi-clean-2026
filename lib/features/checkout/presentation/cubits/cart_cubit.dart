import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gold_taxi/models/cart_item_model.dart';
import 'package:gold_taxi/models/product_model.dart';
import 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  static const String _boxName = 'cart_items_box';

  CartCubit() : super(CartInitial()) {
    loadCart();
  }

  /// Load cart items from Hive
  Future<void> loadCart() async {
    final box = await Hive.openBox(_boxName);
    final itemsJson = box.get('items') as List?;
    if (itemsJson != null) {
      final items = itemsJson
          .map(
            (json) =>
                CartItemModel.fromJson(Map<String, dynamic>.from(json as Map)),
          )
          .toList();
      if (isClosed) return;
      emit(CartLoaded(items: items));
    } else {
      if (isClosed) return;
      emit(const CartLoaded(items: []));
    }
  }

  /// Add a product to the cart
  Future<void> addProduct(ProductModel product, {int quantity = 1}) async {
    final currentState = state;
    if (currentState is CartLoaded) {
      final updatedItems = List<CartItemModel>.from(currentState.items);
      final index = updatedItems.indexWhere(
        (item) => item.product.id == product.id,
      );

      if (index >= 0) {
        final existingItem = updatedItems[index];
        updatedItems[index] = existingItem.copyWith(
          quantity: existingItem.quantity + quantity,
        );
      } else {
        updatedItems.add(CartItemModel(product: product, quantity: quantity));
      }

      emit(CartLoaded(items: updatedItems));
      await _persistItems(updatedItems);
    }
  }

  /// Remove a product from the cart
  Future<void> removeProduct(int productId) async {
    final currentState = state;
    if (currentState is CartLoaded) {
      final updatedItems = currentState.items
          .where((item) => item.product.id != productId)
          .toList();
      emit(CartLoaded(items: updatedItems));
      await _persistItems(updatedItems);
    }
  }

  /// Update quantity of an item
  Future<void> updateQuantity(int productId, int quantity) async {
    final currentState = state;
    if (currentState is CartLoaded) {
      if (quantity <= 0) {
        await removeProduct(productId);
        return;
      }
      final updatedItems = currentState.items.map((item) {
        if (item.product.id == productId) {
          return item.copyWith(quantity: quantity);
        }
        return item;
      }).toList();

      emit(CartLoaded(items: updatedItems));
      await _persistItems(updatedItems);
    }
  }

  /// Clear all items in the cart
  Future<void> clearCart() async {
    emit(const CartLoaded(items: []));
    final box = await Hive.openBox(_boxName);
    await box.delete('items');
  }

  /// Save items list to Hive
  Future<void> _persistItems(List<CartItemModel> items) async {
    final box = await Hive.openBox(_boxName);
    final itemsJson = items.map((item) => item.toJson()).toList();
    await box.put('items', itemsJson);
  }
}
