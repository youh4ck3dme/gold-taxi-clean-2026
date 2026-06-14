import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/service_locator.dart';
import '../features/auth/presentation/cubits/auth_cubit.dart';
import '../features/auth/presentation/cubits/auth_state.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/blog/presentation/pages/blog_page.dart';
import '../features/events/presentation/pages/events_page.dart';
import '../features/blog/presentation/pages/blog_detail_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/products/presentation/pages/products_page.dart';
import '../features/products/presentation/pages/product_detail_page.dart';
import '../features/services/presentation/pages/services_page.dart';
import '../features/services/presentation/pages/service_detail_page.dart';
import '../features/events/presentation/pages/event_detail_page.dart';
import '../features/checkout/presentation/pages/cart_page.dart';
import '../features/checkout/presentation/pages/checkout_page.dart';
import '../features/checkout/presentation/pages/order_confirmation_page.dart';
import '../features/services/presentation/pages/booking_page.dart';
import '../features/services/presentation/bloc/bookings_bloc.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/profile/presentation/pages/edit_profile_page.dart';
import '../features/search/presentation/pages/search_page.dart';
import '../features/faq/presentation/pages/faq_page.dart';
import '../features/insolvency_monitoring/presentation/pages/insolvency_dashboard_page.dart';
import 'package:gold_taxi/features/map/presentation/pages/map_page.dart';
import 'package:gold_taxi/features/map/presentation/pages/ride_request_page.dart';
import 'package:gold_taxi/features/map/presentation/pages/active_ride_page.dart';
import 'package:gold_taxi/features/map/presentation/cubits/map_cubit.dart';
import 'package:gold_taxi/features/map/presentation/cubits/ride_cubit.dart';
import '../core/services/mock_geocoding_service.dart';
import '../features/profile/presentation/pages/driver_dashboard_page.dart';
import '../features/profile/presentation/pages/admin_dashboard_page.dart';
import '../features/shared/presentation/widgets/main_shell.dart';
import '../core/constants/feature_flags.dart';
import '../models/post_model.dart';
import '../models/product_model.dart';
import '../models/service_model.dart';
import '../models/event_model.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: GoRouterRefreshStream(getIt<AuthCubit>().stream),
  redirect: (context, state) {
    final authState = getIt<AuthCubit>().state;
    final isLoggingIn = state.matchedLocation == '/login';

    // Feature Flags Check
    if (state.matchedLocation.startsWith('/blog') && !FeatureFlags.blogEnabled) return '/';
    if (state.matchedLocation.startsWith('/products') && !FeatureFlags.productsEnabled) return '/';
    if (state.matchedLocation.startsWith('/events') && !FeatureFlags.eventsEnabled) return '/';
    if (state.matchedLocation.startsWith('/insolvency') && !FeatureFlags.insolvencyEnabled) return '/';

    if (authState is Authenticated) {
      final user = authState.user;
      if (state.matchedLocation == '/driver' && !user.isDriver) return '/';
      if (state.matchedLocation == '/admin' && !user.isAdmin) return '/';
    }

    if (authState is AuthInitial) {
      getIt<AuthCubit>().checkAuthStatus();
      return null;
    }

    if (authState is AuthLoading) {
      return null;
    }

    if (authState is Unauthenticated && !isLoggingIn) {
      return '/login';
    }

    if (authState is Authenticated && isLoggingIn) {
      return '/';
    }

    return null;
  },
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return MainShell(child: child);
      },
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomePage()),
        GoRoute(path: '/services', builder: (context, state) => const ServicesPage()),
        GoRoute(path: '/products', builder: (context, state) => const ProductsPage()),
        GoRoute(path: '/events', builder: (context, state) => const EventsPage()),
        GoRoute(path: '/blog', builder: (context, state) => const BlogPage()),
        GoRoute(
          path: '/map',
          builder: (context, state) => BlocProvider<MapCubit>(
            create: (_) => getIt<MapCubit>(),
            child: const MapPage(),
          ),
        ),
      ],
    ),
    // Auth routes
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    // Feature detail routes (outside ShellRoute for full-screen overlay)
    GoRoute(
      path: '/blog/detail',
      builder: (context, state) {
        final post = state.extra as PostModel;
        return BlogDetailPage(post: post);
      },
    ),
    GoRoute(
      path: '/products/detail',
      builder: (context, state) {
        final product = state.extra as ProductModel;
        return ProductDetailPage(product: product);
      },
    ),
    GoRoute(
      path: '/services/detail',
      builder: (context, state) {
        final service = state.extra as ServiceModel;
        return ServiceDetailPage(service: service);
      },
    ),
    GoRoute(
      path: '/events/detail',
      builder: (context, state) {
        final event = state.extra as EventModel;
        return EventDetailPage(event: event);
      },
    ),
    GoRoute(path: '/cart', builder: (context, state) => const CartPage()),
    GoRoute(path: '/checkout', builder: (context, state) => const CheckoutPage()),
    GoRoute(
      path: '/order-confirmation',
      builder: (context, state) {
        final orderId = state.extra as String;
        return OrderConfirmationPage(orderId: orderId);
      },
    ),
    GoRoute(
      path: '/booking',
      builder: (context, state) {
        final service = state.extra as ServiceModel;
        return BlocProvider(
          create: (_) => getIt<BookingsBloc>(),
          child: BookingPage(service: service),
        );
      },
    ),
    GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
    GoRoute(path: '/profile/edit', builder: (context, state) => const EditProfilePage()),
    GoRoute(path: '/driver', builder: (context, state) => const DriverDashboardPage()),
    GoRoute(path: '/admin', builder: (context, state) => const AdminDashboardPage()),
    GoRoute(path: '/search', builder: (context, state) => const SearchPage()),
    GoRoute(
      path: '/ride-request',
      builder: (context, state) {
        final destination = state.extra as LocationModel;
        return RideRequestPage(destination: destination);
      },
    ),
    GoRoute(
      path: '/active-ride',
      builder: (context, state) => BlocProvider<RideCubit>(
        create: (_) => getIt<RideCubit>(),
        child: const ActiveRidePage(),
      ),
    ),
    GoRoute(path: '/faq', builder: (context, state) => const FaqPage()),
    GoRoute(path: '/insolvency', builder: (context, state) => const InsolvencyDashboardPage()),
  ],
  errorBuilder: (context, state) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(child: Text('Route not found: ${state.uri.toString()}')),
    );
  },
);
