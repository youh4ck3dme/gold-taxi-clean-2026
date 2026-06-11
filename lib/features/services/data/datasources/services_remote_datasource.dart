import 'package:gold_taxi/core/constants/api_constants.dart';
import 'package:gold_taxi/core/services/api_service.dart';
import 'package:gold_taxi/models/service_model.dart';

class ServicesRemoteDataSource {
  final ApiService _apiService;

  ServicesRemoteDataSource(this._apiService);

  /// Fetch services from JetEngine API
  Future<List<ServiceModel>> fetchServices({int page = 1, int perPage = 10, String? search}) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'per_page': perPage,
    };
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final response = await _apiService.get(
      ApiConstants.servicesEndpoint,
      queryParameters: queryParams,
    );

    if (response is List) {
      return response.map((json) => ServiceModel.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
