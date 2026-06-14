import 'package:equatable/equatable.dart';

abstract class ServicesEvent extends Equatable {
  const ServicesEvent();

  @override
  List<Object?> get props => [];
}

class FetchServices extends ServicesEvent {
  final String? search;
  final bool isRefresh;

  const FetchServices({this.search, this.isRefresh = false});

  @override
  List<Object?> get props => [search, isRefresh];
}
