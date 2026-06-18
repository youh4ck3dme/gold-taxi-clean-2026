import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:gold_taxi/models/event_model.dart';
import '../datasources/events_local_datasource.dart';
import '../datasources/events_remote_datasource.dart';

class EventsRepository {
  final EventsRemoteDataSource _remoteDataSource;
  final EventsLocalDataSource _localDataSource;
  final Connectivity _connectivity;

  EventsRepository(
    this._remoteDataSource,
    this._localDataSource,
    this._connectivity,
  );

  /// Fetch events from remote API or fallback to local cache
  Future<List<EventModel>> getEvents({
    int page = 1,
    int perPage = 10,
    String? search,
  }) async {
    final connectivityResult = await _connectivity.checkConnectivity();
    final isOnline = !connectivityResult.contains(ConnectivityResult.none);

    if (isOnline) {
      try {
        final events = await _remoteDataSource.fetchEvents(
          page: page,
          perPage: perPage,
          search: search,
        );
        if (page == 1 && (search == null || search.isEmpty)) {
          await _localDataSource.cacheEvents(events);
        }
        return events;
      } catch (_) {
        if (page == 1 && (search == null || search.isEmpty)) {
          return await _localDataSource.getCachedEvents();
        }
        rethrow;
      }
    } else {
      if (page == 1 && (search == null || search.isEmpty)) {
        return await _localDataSource.getCachedEvents();
      }
      return [];
    }
  }
}
