import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/search_repository.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchRepository _searchRepository;
  Timer? _debounceTimer;

  SearchBloc(this._searchRepository) : super(const SearchInitial()) {
    on<LoadSearchHistory>(_onLoadSearchHistory);
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<ClearHistory>(_onClearHistory);
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }

  Future<void> _onLoadSearchHistory(LoadSearchHistory event, Emitter<SearchState> emit) async {
    final history = await _searchRepository.getSearchHistory();
    emit(SearchInitial(history: history));
  }

  Future<void> _onSearchQueryChanged(SearchQueryChanged event, Emitter<SearchState> emit) async {
    _debounceTimer?.cancel();
    
    if (event.query.trim().isEmpty) {
      final history = await _searchRepository.getSearchHistory();
      emit(SearchInitial(history: history));
      return;
    }

    final completer = Completer<void>();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      add(LoadSearchHistory()); // Triggers history loading internally if needed, or we just execute search
      completer.complete();
    });

    await completer.future;

    emit(SearchLoading());
    try {
      final results = await _searchRepository.searchAll(event.query);
      await _searchRepository.addToSearchHistory(event.query);
      emit(SearchSuccess(result: results, query: event.query));
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }

  Future<void> _onClearHistory(ClearHistory event, Emitter<SearchState> emit) async {
    await _searchRepository.clearSearchHistory();
    emit(const SearchInitial(history: []));
  }
}
