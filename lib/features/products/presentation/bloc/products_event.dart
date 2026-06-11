import 'package:equatable/equatable.dart';

abstract class ProductsEvent extends Equatable {
  const ProductsEvent();

  @override
  List<Object?> get props => [];
}

class FetchProducts extends ProductsEvent {
  final String? search;
  final bool isRefresh;

  const FetchProducts({this.search, this.isRefresh = false});

  @override
  List<Object?> get props => [search, isRefresh];
}
