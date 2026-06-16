import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';

import 'core/constants/app_constants.dart';
import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'core/services/api_service.dart';
import 'routes/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // 1. Load Environment Settings
  var envLoaded = false;
  if (kIsWeb) {
    debugPrint(
      '🌐 Web environment detected, using compile-time environment defines.',
    );
  } else {
    try {
      await dotenv.load(fileName: ".env");
      envLoaded = true;
    } catch (e) {
      debugPrint(
        '⚠️ Note: .env file not found, using environment defines if available.',
      );
    }
  }

  // 2. Setup Service Locator (Dependency Injection)
  // Check Dart defines first, then .env, then default
  final backendModeStr = const String.fromEnvironment('BACKEND_MODE').isNotEmpty
      ? const String.fromEnvironment('BACKEND_MODE')
      : (envLoaded ? dotenv.env['BACKEND_MODE'] : null) ?? 'mock';

  final backendMode = backendModeStr.toLowerCase() == 'supabase'
      ? BackendMode.supabase
      : BackendMode.mock;

  await setupServiceLocator(mode: backendMode);
  debugPrint('🏗️ Service Locator initialized in $backendMode mode.');

  // 3. Enable Mock Mode for DEMO/PRODUCTION (real server unreachable)
  if (backendMode == BackendMode.mock) {
    ApiService.enableMockMode();
    debugPrint('🎭 MOCK MODE ENABLED - Demo mode with mock data');
  }

  // 4. Resilient Firebase Initialization
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('🔥 Firebase Web initialized successfully.');
    } else {
      // Mobile platforms fallback: Initialize only if native configurations exist
      await Firebase.initializeApp();
      debugPrint('🔥 Firebase Mobile initialized successfully.');
    }
  } catch (e) {
    // Skips initialization if missing native config files on iOS/Android
    debugPrint('⚠️ Warning: Firebase skipped or failed to initialize: $e');
  }

  // 5. Initialize Supabase
  try {
    final supabaseUrl = const String.fromEnvironment('SUPABASE_URL').isNotEmpty
        ? const String.fromEnvironment('SUPABASE_URL')
        : (envLoaded ? dotenv.env['SUPABASE_URL'] : null);

    final supabaseAnonKey =
        const String.fromEnvironment('SUPABASE_ANON_KEY').isNotEmpty
        ? const String.fromEnvironment('SUPABASE_ANON_KEY')
        : (envLoaded ? dotenv.env['SUPABASE_ANON_KEY'] : null);

    if (supabaseUrl == null ||
        supabaseUrl.isEmpty ||
        supabaseAnonKey == null ||
        supabaseAnonKey.isEmpty) {
      debugPrint(
        '⚠️ Supabase skipped: SUPABASE_URL or SUPABASE_ANON_KEY is not configured.',
      );
    } else {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseAnonKey,
      );
      debugPrint('⚡ Supabase Client initialized successfully.');
    }
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
