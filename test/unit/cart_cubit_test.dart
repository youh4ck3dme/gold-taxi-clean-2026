import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gold_taxi/features/checkout/presentation/cubits/cart_cubit.dart';
import 'package:gold_taxi/features/checkout/presentation/cubits/cart_state.dart';
import 'package:gold_taxi/models/product_model.dart';

void main() {
  late CartCubit cartCubit;
  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
  });

  setUp(() async {
    // Clear box if it exists
    if (Hive.isBoxOpen('cart_items_box')) {
      await Hive.box('cart_items_box').clear();
    }
    cartCubit = CartCubit();
    // Wait deterministically for the asynchronous loadCart called in constructor.
    if (cartCubit.state is! CartLoaded) {
      await cartCubit.stream
          .firstWhere((state) => state is CartLoaded)
          .timeout(const Duration(seconds: 3));
    }
  });

  tearDown(() async {
    await cartCubit.close();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('CartCubit Tests', () {
    const testProduct = ProductModel(
      id: 1,
      name: 'Test Product',
      description: 'Test Description',
      price: 10.0,
      salePrice: 8.0,
      sku: 'SKU-1',
      stock: 10,
    );

    test('Initial state loads empty items list', () {
      expect(cartCubit.state, isA<CartLoaded>());
      expect((cartCubit.state as CartLoaded).items, isEmpty);
    });

    test('addProduct adds new product to cart', () async {
      await cartCubit.addProduct(testProduct, quantity: 2);

      expect(cartCubit.state, isA<CartLoaded>());
      final state = cartCubit.state as CartLoaded;
      expect(state.items, hasLength(1));
      expect(state.items.first.product.id, 1);
      expect(state.items.first.quantity, 2);
    });

    test('addProduct increments quantity if product already in cart', () async {
      await cartCubit.addProduct(testProduct, quantity: 2);
      await cartCubit.addProduct(testProduct, quantity: 3);

      final state = cartCubit.state as CartLoaded;
      expect(state.items, hasLength(1));
      expect(state.items.first.quantity, 5);
    });

    test('updateQuantity modifies quantity of cart item', () async {
      await cartCubit.addProduct(testProduct, quantity: 2);
      await cartCubit.updateQuantity(1, 4);

      final state = cartCubit.state as CartLoaded;
      expect(state.items.first.quantity, 4);
    });

    test('updateQuantity removes item if quantity set to 0 or less', () async {
      await cartCubit.addProduct(testProduct, quantity: 2);
      await cartCubit.updateQuantity(1, 0);

      final state = cartCubit.state as CartLoaded;
      expect(state.items, isEmpty);
    });

    test('removeProduct deletes item from cart', () async {
      await cartCubit.addProduct(testProduct, quantity: 2);
      await cartCubit.removeProduct(1);

      final state = cartCubit.state as CartLoaded;
      expect(state.items, isEmpty);
    });

    test('clearCart empties the cart', () async {
      await cartCubit.addProduct(testProduct, quantity: 2);
      await cartCubit.clearCart();

      final state = cartCubit.state as CartLoaded;
      expect(state.items, isEmpty);
    });
  });
}
