import 'package:equatable/equatable.dart';

abstract class FaqEvent extends Equatable {
  const FaqEvent();

  @override
  List<Object?> get props => [];
}

class FetchFaqs extends FaqEvent {
  final bool isRefresh;

  const FetchFaqs({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}
