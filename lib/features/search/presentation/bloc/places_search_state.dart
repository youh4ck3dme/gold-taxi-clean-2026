part of 'places_search_cubit.dart';

abstract class PlacesSearchState extends Equatable {
  const PlacesSearchState();

  @override
  List<Object?> get props => [];
}

class PlacesSearchInitial extends PlacesSearchState {}

class PlacesSearchLoading extends PlacesSearchState {}

class PlacesSearchLoaded extends PlacesSearchState {
  final List<PlaceModel> results;
  final bool isSearching;
  final PlaceModel? homePlace;
  final PlaceModel? workPlace;

  const PlacesSearchLoaded({
    required this.results,
    this.isSearching = false,
    this.homePlace,
    this.workPlace,
  });

  @override
  List<Object?> get props => [results, isSearching, homePlace, workPlace];
}

class PlacesSearchError extends PlacesSearchState {
  final String message;

  const PlacesSearchError({required this.message});

  @override
  List<Object> get props => [message];
}
