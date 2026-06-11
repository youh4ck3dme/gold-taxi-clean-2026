import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/events_repository.dart';
import 'events_event.dart';
import 'events_state.dart';

class EventsBloc extends Bloc<EventsEvent, EventsState> {
  final EventsRepository _eventsRepository;

  EventsBloc(this._eventsRepository) : super(EventsInitial()) {
    on<FetchEvents>(_onFetchEvents);
  }

  Future<void> _onFetchEvents(FetchEvents event, Emitter<EventsState> emit) async {
    if (state is! EventsLoaded || event.isRefresh || event.search != null) {
      emit(EventsLoading());
    }

    try {
      final events = await _eventsRepository.getEvents(
        page: 1,
        search: event.search,
      );
      emit(EventsLoaded(events: events));
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }
}
