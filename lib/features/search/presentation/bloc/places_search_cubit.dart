// ignore_for_file: prefer_initializing_formals

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gold_taxi/features/search/data/models/place_model.dart';
import 'package:gold_taxi/features/search/data/places_repository.dart';
import 'package:gold_taxi/features/search/data/recent_places_repository.dart';

part 'places_search_state.dart';

class PlacesSearchCubit extends Cubit<PlacesSearchState> {
  final PlacesRepository _placesRepository;
  final RecentPlacesRepository _recentPlacesRepository;
  final BehaviorSubject<String> _searchSubject = BehaviorSubject<String>();

  LatLng? _currentLocation;

  PlacesSearchCubit({
    required this._placesRepository,
    required RecentPlacesRepository recentPlacesRepository,
  })  : _recentPlacesRepository = recentPlacesRepository,
        super(PlacesSearchInitial()) {
    _initSearchDebounce();
  }

  void setCurrentLocation(LatLng location) {
    _currentLocation = location;
  }

  void _initSearchDebounce() {
    _searchSubject.debounceTime(const Duration(milliseconds: 300)).listen((query) async {
      if (query.isEmpty) {
        await loadInitialData();
        return;
      }

      emit(PlacesSearchLoading());
      try {
        final results = await _placesRepository.autocomplete(query, _currentLocation);
        emit(PlacesSearchLoaded(results: results, isSearching: true));
      } catch (e) {
        emit(PlacesSearchError(message: e.toString()));
      }
    });
  }

  void onQueryChanged(String query) {
    _searchSubject.add(query);
  }

  Future<void> loadInitialData() async {
    emit(PlacesSearchLoading());
    try {
      await _recentPlacesRepository.init();
      final recentPlaces = await _recentPlacesRepository.getRecentPlaces();
      final homePlace = await _recentPlacesRepository.getPinnedPlace('home');
      final workPlace = await _recentPlacesRepository.getPinnedPlace('work');

      emit(PlacesSearchLoaded(
        results: recentPlaces,
        isSearching: false,
        homePlace: homePlace,
        workPlace: workPlace,
      ));
    } catch (e) {
      emit(PlacesSearchError(message: e.toString()));
    }
  }

  Future<PlaceModel?> selectPlace(PlaceModel place) async {
    try {
      if (place.lat != null && place.lng != null) {
        await _recentPlacesRepository.saveRecentPlace(place);
        return place;
      }

      emit(PlacesSearchLoading());
      final details = await _placesRepository.getPlaceDetails(place.placeId, _currentLocation);
      await _recentPlacesRepository.saveRecentPlace(details);

      await loadInitialData();
      return details;
    } catch (e) {
      emit(PlacesSearchError(message: e.toString()));
      return null;
    }
  }

  Future<void> setPinnedPlace(String type, PlaceModel place) async {
    try {
      PlaceModel placeToSave = place;
      if (place.lat == null || place.lng == null) {
        placeToSave = await _placesRepository.getPlaceDetails(place.placeId, _currentLocation);
      }
      await _recentPlacesRepository.savePinnedPlace(type, placeToSave);
      await loadInitialData();
    } catch (e) {
      emit(PlacesSearchError(message: 'Nepodarilo sa uložiť miesto: $e'));
    }
  }

  @override
  Future<void> close() {
    _searchSubject.close();
    return super.close();
  }
}
