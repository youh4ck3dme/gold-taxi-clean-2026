import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold_taxi/models/product_model.dart';
import 'package:gold_taxi/core/widgets/buttons/primary_button.dart';
import 'package:gold_taxi/features/shared/presentation/widgets/reviews_list.dart';
import 'package:gold_taxi/features/checkout/presentation/cubits/cart_cubit.dart';
import 'package:go_router/go_router.dart';

class ProductDetailPage extends StatelessWidget {
  final ProductModel product;

  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail produktu')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (product.images.isNotEmpty)
              Image.network(
                product.images.first,
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  height: 300,
                  child: Center(child: Icon(Icons.image_not_supported, size: 60)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${product.price.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        (product.stock ?? 0) > 0 ? 'Na sklade (${product.stock} ks)' : 'Vypredané',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: (product.stock ?? 0) > 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if ((product.sku?.isNotEmpty ?? false))
                    Text(
                      'SKU: ${product.sku}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  const Divider(height: 32),
                  const Text(
                    'Popis produktu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ''),
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: 'Pridať do košíka',
                    onPressed: (product.stock ?? 0) > 0
                        ? () {
                            context.read<CartCubit>().addProduct(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product.name} pridaný do košíka!'),
                                action: SnackBarAction(
                                  label: 'Zobraziť košík',
                                  onPressed: () {
                                    context.push('/cart');
                                  },
                                ),
                              ),
                            );
                          }
                        : null,
                  ),
                  const Divider(height: 32),
                  ReviewsList(postId: int.tryParse(product.id) ?? 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
