import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/config/app_config.dart';
import 'core/constants/app_constants.dart';
import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'core/services/api_service.dart';
import 'routes/app_router.dart';
import 'core/utils/url_strategy.dart';

Future<void> mainCommon(AppConfig config) async {
  configureUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  // Enforce security check: mock mode must never run in production environment
  if (config.environment == AppEnvironment.prod && config.enableMockMode) {
    throw StateError('Security violation: Mock mode cannot be enabled in a production environment.');
  }

  // Initialize Hive for local storage
  await Hive.initFlutter();



  // 2. Setup Service Locator (Dependency Injection)
  final backendMode = config.enableMockMode ? BackendMode.mock : BackendMode.supabase;
  await setupServiceLocator(mode: backendMode);
  debugPrint('🏗️ Service Locator initialized in $backendMode mode.');

  // 3. Log Mock Mode if enabled
  if (config.enableMockMode) {
    debugPrint('🎭 MOCK MODE ENABLED - Demo mode with mock data');
  }

  // 5. Setup standard error handlers (No Firebase/Crashlytics)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('🔴 Uncaught Error: $error');
    debugPrint(stack.toString());
    return true;
  };

  // 6. Initialize Supabase
  try {
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabaseAnonKey,
    );
    debugPrint('⚡ Supabase Client initialized successfully.');
  } catch (e) {
    debugPrint('🔴 Error: Supabase initialization failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
