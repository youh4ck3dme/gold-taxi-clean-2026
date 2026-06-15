import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';

import 'core/config/app_config.dart';
import 'core/constants/app_constants.dart';
import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'core/services/api_service.dart';
import 'routes/app_router.dart';

Future<void> mainCommon(AppConfig config) async {
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

  // 4. Resilient Firebase Initialization
  bool firebaseInitialized = false;
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      firebaseInitialized = true;
      debugPrint('🔥 Firebase Web initialized successfully.');
    } else {
      // Mobile platforms fallback: Initialize only if native configurations exist
      await Firebase.initializeApp();
      firebaseInitialized = true;
      debugPrint('🔥 Firebase Mobile initialized successfully.');
    }
  } catch (e) {
    debugPrint('⚠️ Warning: Firebase skipped or failed to initialize: $e');
  }

  // 5. Setup Crashlytics Error Handlers if Firebase is initialized
  if (firebaseInitialized && !kIsWeb) {
    try {
      // Enable Crashlytics collection in production, or if configured
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(config.enableAnalytics);
      
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        FirebaseCrashlytics.instance.recordFlutterError(details);
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      debugPrint('🛡️ Firebase Crashlytics handlers registered.');
    } catch (e) {
      debugPrint('⚠️ Warning: Crashlytics configuration failed: $e');
    }
  } else {
    // Fallback error logging for development/mock mode without Firebase
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('🔴 Uncaught Error: $error');
      debugPrint(stack.toString());
      return true;
    };
  }

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
