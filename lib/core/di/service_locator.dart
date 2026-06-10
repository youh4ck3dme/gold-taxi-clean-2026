import 'package:get_it/get_it.dart';

import '../services/api_service.dart';

final getIt = GetIt.instance;

/// Setup Service Locator (Dependency Injection)
Future<void> setupServiceLocator() async {
  // Register services as singletons
  getIt.registerSingleton<ApiService>(ApiService());

  // TODO: Register other services as needed
  // getIt.registerSingleton<CacheService>(CacheService());
  // getIt.registerSingleton<NotificationService>(NotificationService());
  // getIt.registerSingleton<LocationService>(LocationService());

  // TODO: Register repositories
  // getIt.registerSingleton<AuthRepository>(AuthRepository(getIt<ApiService>()));
  // getIt.registerSingleton<HomeRepository>(HomeRepository(getIt<ApiService>()));
}
