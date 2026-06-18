import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gold_taxi/features/products/presentation/bloc/products_bloc.dart';
import 'package:gold_taxi/features/products/presentation/bloc/products_event.dart';
import 'package:gold_taxi/features/products/presentation/bloc/products_state.dart';
import 'package:gold_taxi/features/products/data/repositories/products_repository.dart';
import 'package:gold_taxi/models/product_model.dart';

class MockProductsRepository extends Mock implements ProductsRepository {}

void main() {
  late ProductsBloc productsBloc;
  late MockProductsRepository mockProductsRepository;

  setUp(() {
    mockProductsRepository = MockProductsRepository();
    productsBloc = ProductsBloc(mockProductsRepository);
  });

  tearDown(() {
    productsBloc.close();
  });

  group('ProductsBloc Tests', () {
    const testProduct = ProductModel(
      id: '1',
      name: 'Test Product',
      description: 'Test Description',
      price: 10.0,
      salePrice: 8.0,
      sku: 'SKU-1',
      stock: 10,
      images: ['https://test.com/image.png'],
      categories: ['Test Category'],
    );

    test('Initial state is ProductsInitial', () {
      expect(productsBloc.state, isA<ProductsInitial>());
    });

    test('FetchProducts emits [ProductsLoading, ProductsLoaded] when repository succeeds', () async {
      when(() => mockProductsRepository.getProducts(
            page: any(named: 'page'),
            search: any(named: 'search'),
          )).thenAnswer((_) async => [testProduct]);

      expectLater(
        productsBloc.stream,
        emitsInOrder([
          isA<ProductsLoading>(),
          isA<ProductsLoaded>(),
        ]),
      );

      productsBloc.add(const FetchProducts());
    });

    test('FetchProducts emits [ProductsLoading, ProductsError] when repository throws error', () async {
      when(() => mockProductsRepository.getProducts(
            page: any(named: 'page'),
            search: any(named: 'search'),
          )).thenThrow(Exception('API error'));

      expectLater(
        productsBloc.stream,
        emitsInOrder([
          isA<ProductsLoading>(),
          isA<ProductsError>(),
        ]),
      );

      productsBloc.add(const FetchProducts());
    });
  });
}
