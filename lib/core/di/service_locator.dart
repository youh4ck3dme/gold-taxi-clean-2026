import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../services/secure_storage_service.dart';
import '../services/notification_service.dart';
import '../services/deep_link_service.dart';
import '../interceptors/auth_interceptor.dart';

import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/presentation/cubits/auth_cubit.dart';
import '../../features/map/data/repositories/driver_position_repository.dart';
import '../../features/map/data/services/driver_profile_service.dart';
import 'package:gold_taxi/features/map/presentation/cubits/map_cubit.dart';
import '../../features/blog/data/datasources/local/blog_local_datasource.dart';
import '../../features/blog/data/datasources/remote/blog_remote_datasource.dart';
import '../../features/blog/data/repositories/blog_repository.dart';
import '../../features/blog/presentation/bloc/blog_bloc.dart';

import '../../features/products/data/datasources/products_local_datasource.dart';
import '../../features/products/data/datasources/products_remote_datasource.dart';
import '../../features/products/data/repositories/products_repository.dart';
import '../../features/products/presentation/bloc/products_bloc.dart';

import '../../features/services/data/datasources/services_local_datasource.dart';
import '../../features/services/data/datasources/services_remote_datasource.dart';
import '../../features/services/data/repositories/services_repository.dart';
import '../../features/services/presentation/bloc/services_bloc.dart';

import '../../features/events/data/datasources/events_local_datasource.dart';
import '../../features/events/data/datasources/events_remote_datasource.dart';
import '../../features/events/data/repositories/events_repository.dart';
import '../../features/events/presentation/bloc/events_bloc.dart';

import '../../features/shared/data/datasources/reviews_local_datasource.dart';
import '../../features/shared/data/datasources/reviews_remote_datasource.dart';
import '../../features/shared/data/repositories/reviews_repository.dart';
import '../../features/shared/presentation/bloc/reviews_bloc.dart';
import '../../features/checkout/presentation/cubits/cart_cubit.dart';

import '../../features/services/data/datasources/bookings_remote_datasource.dart';
import '../../features/services/data/repositories/bookings_repository.dart';
import '../../features/services/presentation/bloc/bookings_bloc.dart';

import '../../features/profile/data/repositories/profile_repository.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/map/presentation/cubits/ride_cubit.dart';

import '../../features/search/data/repositories/search_repository.dart';
import '../../features/search/presentation/bloc/search_bloc.dart';
import '../../features/map/data/repositories/ride_repository.dart';
import '../../features/map/data/repositories/mock_ride_repository.dart';
import '../../features/map/data/repositories/supabase_ride_repository.dart';

import '../../features/faq/data/repositories/faq_repository.dart';
import '../../features/faq/presentation/bloc/faq_bloc.dart';
import '../../features/insolvency_monitoring/presentation/cubits/insolvency_cubit.dart';
import '../services/insolvency_predictor_service.dart';

enum BackendMode { mock, supabase }

final getIt = GetIt.instance;

/// Setup Service Locator (Dependency Injection)
Future<void> setupServiceLocator({BackendMode mode = BackendMode.mock}) async {
  // Register services as singletons
  getIt.registerLazySingleton<LocalStorageService>(() => SecureStorageService());
  getIt.registerLazySingleton<AuthInterceptor>(() => AuthInterceptor(getIt<LocalStorageService>()));
  getIt.registerSingleton<ApiService>(ApiService(getIt<AuthInterceptor>(), enableMockMode: mode == BackendMode.mock));
  getIt.registerLazySingleton<Connectivity>(() => Connectivity());
  getIt.registerLazySingleton<CartCubit>(() => CartCubit());
  getIt.registerLazySingleton<InsolvencyPredictorService>(() => InsolvencyPredictorService());
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());
  getIt.registerLazySingleton<DeepLinkService>(() => DeepLinkService());

  // Driver Position Repository (in-memory mock; swap for Supabase Realtime when ready)
  getIt.registerLazySingleton<DriverPositionRepository>(() => DriverPositionRepository());
  getIt.registerFactory<MapCubit>(() => MapCubit(getIt<DriverPositionRepository>()));

  // Driver Profile Service for Supabase
  getIt.registerLazySingleton<DriverProfileService>(() => DriverProfileService());

  // Register repositories
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepository(getIt<ApiService>(), getIt<LocalStorageService>()));
  getIt.registerLazySingleton<BlogRepository>(() => BlogRepository(
        getIt<BlogRemoteDataSource>(),
        getIt<BlogLocalDataSource>(),
        getIt<Connectivity>(),
      ));
  getIt.registerLazySingleton<ProductsRepository>(() => ProductsRepository(
        getIt<ProductsRemoteDataSource>(),
        getIt<ProductsLocalDataSource>(),
        getIt<Connectivity>(),
      ));
  getIt.registerLazySingleton<ServicesRepository>(() => ServicesRepository(
        getIt<ServicesRemoteDataSource>(),
        getIt<ServicesLocalDataSource>(),
        getIt<Connectivity>(),
      ));
  getIt.registerLazySingleton<EventsRepository>(() => EventsRepository(
        getIt<EventsRemoteDataSource>(),
        getIt<EventsLocalDataSource>(),
        getIt<Connectivity>(),
      ));
  getIt.registerLazySingleton<ReviewsRepository>(() => ReviewsRepository(
        getIt<ReviewsRemoteDataSource>(),
        getIt<ReviewsLocalDataSource>(),
        getIt<Connectivity>(),
      ));
  getIt.registerLazySingleton<BookingsRepository>(() => BookingsRepository(
        getIt<BookingsRemoteDataSource>(),
        getIt<Connectivity>(),
      ));
  getIt.registerLazySingleton<ProfileRepository>(() => ProfileRepository(
        getIt<ApiService>(),
        getIt<Connectivity>(),
      ));
  getIt.registerLazySingleton<SearchRepository>(() => SearchRepository(
        getIt<ApiService>(),
        getIt<Connectivity>(),
      ));

  // Ride Repository (Swappable)
  if (mode == BackendMode.supabase) {
    getIt.registerLazySingleton<RideRepository>(() => SupabaseRideRepository(Supabase.instance.client));
  } else {
    getIt.registerLazySingleton<RideRepository>(() => MockRideRepository());
  }

  getIt.registerLazySingleton<FaqRepository>(() => FaqRepository(
        getIt<ApiService>(),
        getIt<Connectivity>(),
      ));

  // Register Data Sources
  getIt.registerLazySingleton<BlogRemoteDataSource>(() => BlogRemoteDataSource(getIt<ApiService>()));
  getIt.registerLazySingleton<BlogLocalDataSource>(() => BlogLocalDataSource());
  getIt.registerLazySingleton<ProductsRemoteDataSource>(() => ProductsRemoteDataSource(getIt<ApiService>()));
  getIt.registerLazySingleton<ProductsLocalDataSource>(() => ProductsLocalDataSource());
  getIt.registerLazySingleton<ServicesRemoteDataSource>(() => ServicesRemoteDataSource(getIt<ApiService>()));
  getIt.registerLazySingleton<ServicesLocalDataSource>(() => ServicesLocalDataSource());
  getIt.registerLazySingleton<EventsRemoteDataSource>(() => EventsRemoteDataSource(getIt<ApiService>()));
  getIt.registerLazySingleton<EventsLocalDataSource>(() => EventsLocalDataSource());
  getIt.registerLazySingleton<ReviewsRemoteDataSource>(() => ReviewsRemoteDataSource(getIt<ApiService>()));
  getIt.registerLazySingleton<ReviewsLocalDataSource>(() => ReviewsLocalDataSource());
  getIt.registerLazySingleton<BookingsRemoteDataSource>(() => BookingsRemoteDataSource(getIt<ApiService>()));

  // Register Cubits / Blocs
  getIt.registerLazySingleton<AuthCubit>(() => AuthCubit(getIt<AuthRepository>()));
  getIt.registerFactory<InsolvencyCubit>(() => InsolvencyCubit(getIt<InsolvencyPredictorService>(), getIt<ApiService>()));
  getIt.registerFactory<BlogBloc>(() => BlogBloc(getIt<BlogRepository>()));
  getIt.registerFactory<ProductsBloc>(() => ProductsBloc(getIt<ProductsRepository>()));
  getIt.registerFactory<ServicesBloc>(() => ServicesBloc(getIt<ServicesRepository>()));
  getIt.registerFactory<EventsBloc>(() => EventsBloc(getIt<EventsRepository>()));
  getIt.registerFactory<ReviewsBloc>(() => ReviewsBloc(getIt<ReviewsRepository>()));
  getIt.registerFactory<BookingsBloc>(() => BookingsBloc(getIt<BookingsRepository>()));
  getIt.registerFactory<ProfileBloc>(() => ProfileBloc(getIt<ProfileRepository>()));
  getIt.registerFactory<SearchBloc>(() => SearchBloc(getIt<SearchRepository>()));
  getIt.registerFactory<FaqBloc>(() => FaqBloc(getIt<FaqRepository>()));
  getIt.registerFactory<RideCubit>(() => RideCubit(getIt<RideRepository>()));
}
