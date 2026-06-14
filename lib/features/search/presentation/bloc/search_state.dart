import 'package:equatable/equatable.dart';
import 'package:gold_taxi/features/search/data/models/place_model.dart';
import 'package:gold_taxi/features/search/data/repositories/search_repository.dart';

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

class SearchLoaded extends SearchState {
  final List<PlaceModel> results;
  final bool isSearching;
  final PlaceModel? homePlace;
  final PlaceModel? workPlace;

  const SearchLoaded({
    required this.results,
    this.isSearching = false,
    this.homePlace,
    this.workPlace,
  });

  @override
  List<Object?> get props => [results, isSearching, homePlace, workPlace];
}

class SearchSuccess extends SearchState {
  final SearchResult result;
  final String query;

  const SearchSuccess({required this.result, required this.query});

  @override
  List<Object?> get props => [result, query];
}

class SearchError extends SearchState {
  final String message;

  const SearchError({required this.message});

  @override
  List<Object> get props => [message];
}
