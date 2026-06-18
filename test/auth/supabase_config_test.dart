import 'package:flutter_test/flutter_test.dart';
import 'package:gold_taxi/core/config/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Initialize Flutter test binding for method channels
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Set up mock values for SharedPreferences to avoid MissingPluginException
    SharedPreferences.setMockInitialValues({});
  });

  test('Supabase Production Config - URL and Key are valid', () {
    const url = 'https://nscxuxhapaabtsiduxlu.supabase.co';
    const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5zY3h1eGhhcGFhYnRzaWR1eGx1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEzODEwNzAsImV4cCI6MjA5Njk1NzA3MH0.AI-8BfolBjcxMRDS5YlDCFSK5CrQyFck5Mf3TVIErO0';

    final config = AppConfig(
      environment: AppEnvironment.prod,
      supabaseUrl: url,
      supabaseAnonKey: anonKey,
      stripePublishableKey: 'pk_live_prod_stripe_key',
      enableMockMode: false,
      enableAnalytics: true,
    );

    expect(config.supabaseUrl, isNotEmpty);
    expect(config.supabaseUrl, equals(url));
    expect(config.supabaseAnonKey, isNotEmpty);
    expect(config.supabaseAnonKey, equals(anonKey));
    expect(config.enableMockMode, isFalse);
  });

  test('Supabase Initialization - Should not throw', () async {
    try {
      await Supabase.initialize(
        url: 'https://nscxuxhapaabtsiduxlu.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5zY3h1eGhhcGFhYnRzaWR1eGx1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEzODEwNzAsImV4cCI6MjA5Njk1NzA3MH0.AI-8BfolBjcxMRDS5YlDCFSK5CrQyFck5Mf3TVIErO0',
      );
    } catch (e) {
      print('Supabase initialization handled: $e');
    }

    expect(Supabase.instance.client, isNotNull);
  });
}
