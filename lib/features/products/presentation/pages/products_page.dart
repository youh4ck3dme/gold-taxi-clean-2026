import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gold_taxi/core/di/service_locator.dart';
import 'package:gold_taxi/core/widgets/fields/app_text_field.dart';
import 'package:gold_taxi/core/widgets/loaders/shimmer_list_loader.dart';
import 'package:gold_taxi/models/product_model.dart';
import '../bloc/products_bloc.dart';
import '../bloc/products_event.dart';
import '../bloc/products_state.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProductsBloc>()..add(const FetchProducts()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Produkty')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Builder(
                builder: (context) {
                  return AppTextField(
                    controller: _searchController,
                    labelText: 'Vyhľadať produkty',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        context.read<ProductsBloc>().add(const FetchProducts());
                      },
                    ),
                    textInputAction: TextInputAction.search,
                    onFieldSubmitted: (value) {
                      context.read<ProductsBloc>().add(FetchProducts(search: value));
                    },
                    validator: null,
                    hintText: 'Názov produktu, SKU...',
                    keyboardType: TextInputType.text,
                  );
                }
              ),
            ),
            Expanded(
              child: BlocBuilder<ProductsBloc, ProductsState>(
                builder: (context, state) {
                  if (state is ProductsLoading) {
                    return const ShimmerListLoader();
                  } else if (state is ProductsError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Chyba: ${state.message}', style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<ProductsBloc>().add(FetchProducts(
                                search: _searchController.text,
                                isRefresh: true,
                              ));
                            },
                            child: const Text('Skúsiť znova'),
                          )
                        ],
                      ),
                    );
                  } else if (state is ProductsLoaded) {
                    final products = state.products;
                    if (products.isEmpty) {
                      return const Center(child: Text('Nenašli sa žiadne produkty.'));
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<ProductsBloc>().add(FetchProducts(
                          search: _searchController.text,
                          isRefresh: true,
                        ));
                      },
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return _ProductCard(product: product);
                        },
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () {
          context.push('/products/detail', extra: product);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: product.images.isNotEmpty
                  ? Image.network(
                      product.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.image_not_supported, size: 40),
                      ),
                    )
                  : const Center(child: Icon(Icons.image_not_supported, size: 40)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${product.price.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      if (product.stock > 0)
                        const Icon(Icons.check_circle_outline, color: Colors.green, size: 16)
                      else
                        const Icon(Icons.highlight_off, color: Colors.red, size: 16)
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
