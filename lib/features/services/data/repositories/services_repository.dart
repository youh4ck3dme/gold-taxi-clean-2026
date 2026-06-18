import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:gold_taxi/models/service_model.dart';
import '../datasources/services_local_datasource.dart';
import '../datasources/services_remote_datasource.dart';

class ServicesRepository {
  final ServicesRemoteDataSource _remoteDataSource;
  final ServicesLocalDataSource _localDataSource;
  final Connectivity _connectivity;

  ServicesRepository(
    this._remoteDataSource,
    this._localDataSource,
    this._connectivity,
  );

  /// Fetch services from remote API or fallback to local cache
  Future<List<ServiceModel>> getServices({
    int page = 1,
    int perPage = 10,
    String? search,
  }) async {
    final connectivityResult = await _connectivity.checkConnectivity();
    final isOnline = !connectivityResult.contains(ConnectivityResult.none);

    if (isOnline) {
      try {
        final services = await _remoteDataSource.fetchServices(
          page: page,
          perPage: perPage,
          search: search,
        );
        if (page == 1 && (search == null || search.isEmpty)) {
          await _localDataSource.cacheServices(services);
        }
        return services;
      } catch (_) {
        if (page == 1 && (search == null || search.isEmpty)) {
          return await _localDataSource.getCachedServices();
        }
        rethrow;
      }
    } else {
      if (page == 1 && (search == null || search.isEmpty)) {
        return await _localDataSource.getCachedServices();
      }
      return [];
    }
  }
}
