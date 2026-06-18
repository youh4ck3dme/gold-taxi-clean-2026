import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/products_repository.dart';
import 'products_event.dart';
import 'products_state.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final ProductsRepository _productsRepository;

  ProductsBloc(this._productsRepository) : super(ProductsInitial()) {
    on<FetchProducts>(_onFetchProducts);
  }

  Future<void> _onFetchProducts(
    FetchProducts event,
    Emitter<ProductsState> emit,
  ) async {
    if (state is! ProductsLoaded || event.isRefresh || event.search != null) {
      emit(ProductsLoading());
    }

    try {
      final products = await _productsRepository.getProducts(
        page: 1,
        search: event.search,
      );
      emit(ProductsLoaded(products: products));
    } catch (e) {
      emit(ProductsError(e.toString()));
    }
  }
}
