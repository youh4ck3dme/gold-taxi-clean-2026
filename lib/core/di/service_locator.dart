import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/api_service.dart';
import '../services/mock_api_service.dart';
import '../services/local_storage_service.dart';
import '../services/secure_storage_service.dart';
import '../services/notification_service.dart';
import '../services/deep_link_service.dart';
import '../services/analytics_service.dart';
import '../interceptors/auth_interceptor.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

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
import '../../features/profile/data/repositories/mock_profile_repository.dart';
import '../../features/profile/data/repositories/supabase_profile_repository.dart';
import '../../features/profile/presentation/bloc/profile_cubit.dart';
import '../../features/map/presentation/cubits/ride_cubit.dart';

import '../../features/search/data/repositories/search_repository.dart';
import '../../features/search/presentation/bloc/search_bloc.dart';
import '../../features/search/data/places_repository.dart';
import '../../features/search/data/recent_places_repository.dart';
import '../../features/search/presentation/bloc/places_search_cubit.dart';
import '../../features/map/data/repositories/ride_repository.dart';
import '../../features/map/data/repositories/mock_ride_repository.dart';
import '../../features/map/data/repositories/supabase_ride_repository.dart';
import '../../features/map/data/repositories/promo_repository.dart';
import '../../features/map/data/repositories/mock_promo_repository.dart';
import '../../features/map/data/repositories/supabase_promo_repository.dart';

import '../../features/faq/data/repositories/faq_repository.dart';
import '../../features/faq/presentation/bloc/faq_bloc.dart';
import '../../features/insolvency_monitoring/presentation/cubits/insolvency_cubit.dart';
import '../services/insolvency_predictor_service.dart';

import '../../features/chat/data/repositories/chat_repository.dart';
import '../../features/chat/presentation/bloc/chat_cubit.dart';
import '../../features/earnings/data/repositories/earnings_repository.dart';
import '../../features/earnings/data/repositories/supabase_earnings_repository.dart';
import '../../features/earnings/data/repositories/mock_earnings_repository.dart';

enum BackendMode { mock, supabase }

final getIt = GetIt.instance;

/// Setup Service Locator (Dependency Injection)
Future<void> setupServiceLocator({BackendMode mode = BackendMode.supabase}) async {
  assert(mode != BackendMode.mock || kDebugMode, 'Mock mode is not allowed outside debug/test builds.');
  // Register services as singletons
  getIt.registerLazySingleton<LocalStorageService>(() => SecureStorageService());
  getIt.registerLazySingleton<AuthInterceptor>(() => AuthInterceptor(getIt<LocalStorageService>()));
  if (mode == BackendMode.mock) {
    getIt.registerSingleton<ApiService>(MockApiService(getIt<AuthInterceptor>()));
  } else {
    getIt.registerSingleton<ApiService>(ApiService(getIt<AuthInterceptor>()));
  }
  getIt.registerLazySingleton<Connectivity>(() => Connectivity());
  getIt.registerLazySingleton<CartCubit>(() => CartCubit());
  getIt.registerLazySingleton<InsolvencyPredictorService>(() => InsolvencyPredictorService());
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());
  getIt.registerLazySingleton<DeepLinkService>(() => DeepLinkService());
  getIt.registerLazySingleton<AnalyticsService>(() => AnalyticsService(
        analytics: Firebase.apps.isNotEmpty ? FirebaseAnalytics.instance : null,
        isEnabled: true,
      ));

  // Driver Position Repository (in-memory mock; swap for Supabase Realtime when ready)
  getIt.registerLazySingleton<DriverPositionRepository>(() => DriverPositionRepository());
  getIt.registerFactory<MapCubit>(() => MapCubit(getIt<DriverPositionRepository>()));

  // Driver Profile Service for Supabase
  getIt.registerLazySingleton<DriverProfileService>(() => DriverProfileService());

  // Register repositories
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepository(getIt<LocalStorageService>()));
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

  if (mode == BackendMode.supabase) {
    getIt.registerLazySingleton<ProfileRepository>(() => SupabaseProfileRepository(Supabase.instance.client));
  } else {
    getIt.registerLazySingleton<ProfileRepository>(() => MockProfileRepository());
  }

  getIt.registerLazySingleton<SearchRepository>(() => SearchRepository(
        getIt<ApiService>(),
        getIt<Connectivity>(),
      ));

  // Places Search
  getIt.registerLazySingleton<PlacesRepository>(() => PlacesRepository());
  getIt.registerLazySingleton<RecentPlacesRepository>(() => RecentPlacesRepository());
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

  // Chat Repository
  if (mode == BackendMode.supabase) {
    getIt.registerLazySingleton<ChatRepository>(() => ChatRepository(Supabase.instance.client));
  } else {
    // For now we use the same since ChatRepository expects SupabaseClient.
    // If we build a MockChatRepository, we can swap it here.
    getIt.registerLazySingleton<ChatRepository>(() => ChatRepository(Supabase.instance.client));
  }

  // Earnings Repository
  if (mode == BackendMode.supabase) {
    getIt.registerLazySingleton<EarningsRepository>(() => SupabaseEarningsRepository(
      supabase: Supabase.instance.client,
    ));
  } else {
    getIt.registerLazySingleton<EarningsRepository>(() => MockEarningsRepository());
  }

  // Promo Repository
  if (mode == BackendMode.supabase) {
    getIt.registerLazySingleton<PromoRepository>(() => SupabasePromoRepository(Supabase.instance.client));
  } else {
    getIt.registerLazySingleton<PromoRepository>(() => MockPromoRepository());
  }

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
  getIt.registerFactory<ProfileCubit>(() => ProfileCubit(getIt<ProfileRepository>()));
  getIt.registerFactory<SearchBloc>(() => SearchBloc(getIt<SearchRepository>()));
  getIt.registerFactory<FaqBloc>(() => FaqBloc(getIt<FaqRepository>()));
  getIt.registerFactory<RideCubit>(() => RideCubit(
        getIt<RideRepository>(),
        getIt<PromoRepository>(),
      ));
  getIt.registerFactory<PlacesSearchCubit>(() => PlacesSearchCubit(
        placesRepository: getIt<PlacesRepository>(),
        recentPlacesRepository: getIt<RecentPlacesRepository>(),
      ));
  getIt.registerFactory<ChatCubit>(() => ChatCubit(getIt<ChatRepository>()));
}

