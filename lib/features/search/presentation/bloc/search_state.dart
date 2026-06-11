import 'package:equatable/equatable.dart';
import '../../data/repositories/search_repository.dart';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {
  final List<String> history;

  const SearchInitial({this.history = const []});

  @override
  List<Object?> get props => [history];
}

class SearchLoading extends SearchState {}

class SearchSuccess extends SearchState {
  final SearchResult result;
  final String query;

  const SearchSuccess({required this.result, required this.query});

  @override
  List<Object?> get props => [result, query];
}

class SearchError extends SearchState {
  final String message;

  const SearchError(this.message);

  @override
  List<Object?> get props => [message];
}
