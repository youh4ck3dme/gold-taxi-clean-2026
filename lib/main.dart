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
import 'routes/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // 1. Load Environment Settings
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('⚠️ Warning: Failed to load .env file: $e');
  }

  // 2. Setup Service Locator (Dependency Injection)
  await setupServiceLocator();

  // 3. Resilient Firebase Initialization
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

  // 4. Initialize Supabase
  try {
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'https://your-supabase-url.supabase.co';
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? 'your-supabase-anon-key';

    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
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
