import 'package:gold_taxi/core/constants/api_constants.dart';
import 'package:gold_taxi/core/services/api_service.dart';
import 'package:gold_taxi/models/event_model.dart';

class EventsRemoteDataSource {
  final ApiService _apiService;

  EventsRemoteDataSource(this._apiService);

  /// Fetch events from JetEngine API
  Future<List<EventModel>> fetchEvents({int page = 1, int perPage = 10, String? search}) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'per_page': perPage,
    };
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final response = await _apiService.get(
      ApiConstants.eventsEndpoint,
      queryParameters: queryParams,
    );

    if (response is List) {
      return response.map((json) => EventModel.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
