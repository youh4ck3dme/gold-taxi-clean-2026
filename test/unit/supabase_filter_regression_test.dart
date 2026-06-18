// Regression tests for Supabase filter requirements and production hardening
// These tests ensure no unfiltered SELECT queries exist and production is properly secured

import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

void main() {
  group('Supabase Filter Regression Tests - Rides Repository', () {
    test(
      'getAllRides() uses semantic status filter with RLS documentation',
      () async {
        final filePath = path.join(
          'lib',
          'features',
          'map',
          'data',
          'repositories',
          'supabase_ride_repository.dart',
        );
        final source = await File(filePath).readAsString();

        // Verify semantic filter exists
        expect(source.contains('getAllRides()'), isTrue);
        expect(
          source.contains('.neq(\'status\''),
          isTrue,
          reason: 'Admin ride stream must use semantic status filter .neq()',
        );

        // Verify RLS documentation exists
        expect(
          source.contains('RLS policy:'),
          isTrue,
          reason:
              'Semantic filter must be documented with RLS policy reference',
        );
        expect(
          source.contains('Users can see involved rides'),
          isTrue,
          reason: 'Documentation must reference specific RLS policy',
        );

        // Verify NO .neq('id', '') remains in this method
        final lines = source.split('\n');
        bool inGetAllRides = false;
        bool hasNeqId = false;

        for (final line in lines) {
          if (line.contains('getAllRides()')) {
            inGetAllRides = true;
          }
          if (inGetAllRides && line.contains('.neq(\'id\'')) {
            hasNeqId = true;
            break;
          }
        }

        expect(
          hasNeqId,
          isFalse,
          reason:
              'getAllRides() must NOT use .neq(\'id\') - uses .neq(\'status\') instead',
        );
      },
    );

    test('getCustomerRides() filters by customer_id', () async {
      final filePath = path.join(
        'lib',
        'features',
        'map',
        'data',
        'repositories',
        'supabase_ride_repository.dart',
      );
      final source = await File(filePath).readAsString();

      expect(source.contains('getCustomerRides'), isTrue);
      expect(
        source.contains(".eq('customer_id'"),
        isTrue,
        reason: 'Customer rides must filter by customer_id for security',
      );
    });

    test('getRide() filters by id', () async {
      final filePath = path.join(
        'lib',
        'features',
        'map',
        'data',
        'repositories',
        'supabase_ride_repository.dart',
      );
      final source = await File(filePath).readAsString();

      expect(source.contains('getRide'), isTrue);
      expect(
        source.contains(".eq('id'"),
        isTrue,
        reason: 'Single ride fetch must filter by id',
      );
    });

    test('getActiveRequests() filters by status=requested', () async {
      final filePath = path.join(
        'lib',
        'features',
        'map',
        'data',
        'repositories',
        'supabase_ride_repository.dart',
      );
      final source = await File(filePath).readAsString();

      expect(source.contains('getActiveRequests'), isTrue);
      expect(
        source.contains(".eq('status', 'requested')"),
        isTrue,
        reason: 'Active requests must filter by status',
      );
    });

    test('getDriverActiveRide() filters by driver_id', () async {
      final filePath = path.join(
        'lib',
        'features',
        'map',
        'data',
        'repositories',
        'supabase_ride_repository.dart',
      );
      final source = await File(filePath).readAsString();

      expect(source.contains('getDriverActiveRide'), isTrue);
      expect(
        source.contains(".eq('driver_id'"),
        isTrue,
        reason: 'Driver active ride must filter by driver_id',
      );
    });

    test('All rides SELECT queries have filters', () async {
      final filePath = path.join(
        'lib',
        'features',
        'map',
        'data',
        'repositories',
        'supabase_ride_repository.dart',
      );
      final source = await File(filePath).readAsString();

      // Count .from('rides') occurrences
      final fromRidesMatches = RegExp(r"from\('rides'\)").allMatches(source);

      // Count filter methods
      final filterMethods = RegExp(
        r'\.(eq|neq|gt|lt|gte|lte|in_|filter)\(',
      ).allMatches(source);

      expect(
        fromRidesMatches.length <= filterMethods.length,
        isTrue,
        reason:
            'Every .from(\'rides\') must have a filter. '
            'Found ${fromRidesMatches.length} rides queries and ${filterMethods.length} filters.',
      );
    });
  });

  group('Supabase Filter Regression Tests - FAQ Repository', () {
    test('getFaqs() has documented temporary filter', () async {
      final filePath = path.join(
        'lib',
        'features',
        'faq',
        'data',
        'repositories',
        'faq_repository.dart',
      );
      final source = await File(filePath).readAsString();

      expect(source.contains('.from(\'faqs\')'), isTrue);
      expect(
        source.contains('.neq('),
        isTrue,
        reason: 'FAQ query must have a filter',
      );

      // Verify documentation exists
      expect(
        source.contains('TODO: Consider adding is_active boolean field'),
        isTrue,
        reason: 'Temporary filter must be documented with TODO comment',
      );
      expect(
        source.contains('RLS policy'),
        isTrue,
        reason: 'Documentation must mention RLS policy',
      );
    });

    test('No unfiltered faq SELECT queries exist', () async {
      final filePath = path.join(
        'lib',
        'features',
        'faq',
        'data',
        'repositories',
        'faq_repository.dart',
      );
      final source = await File(filePath).readAsString();

      final fromFaqsMatches = RegExp(r"from\('faqs'\)").allMatches(source);
      final filterMethods = RegExp(
        r'\.(eq|neq|gt|lt|gte|lte|in_|filter)\(',
      ).allMatches(source);

      expect(
        fromFaqsMatches.length <= filterMethods.length,
        isTrue,
        reason: 'Every .from(\'faqs\') must have a filter',
      );
    });
  });

  group('Production Hardening - Environment Validation', () {
    test('Production main_prod.dart has NO default Supabase URL', () async {
      final filePath = path.join('lib', 'main_prod.dart');
      final source = await File(filePath).readAsString();

      // Must use environment variable
      expect(
        source.contains("fromEnvironment('SUPABASE_URL')"),
        isTrue,
        reason: 'Production must read SUPABASE_URL from environment',
      );

      // Must NOT have default value
      expect(
        source.contains("fromEnvironment('SUPABASE_URL', defaultValue:"),
        isFalse,
        reason: 'Production must NOT have defaultValue for SUPABASE_URL',
      );

      // Must NOT hardcode the URL
      expect(
        source.contains('nscxuxhapaabtsiduxlu.supabase.co'),
        isFalse,
        reason: 'Production must NOT hardcode Supabase project URL',
      );
    });

    test(
      'Production main_prod.dart has NO default Supabase anon key',
      () async {
        final filePath = path.join('lib', 'main_prod.dart');
        final source = await File(filePath).readAsString();

        expect(
          source.contains("fromEnvironment('SUPABASE_ANON_KEY')"),
          isTrue,
          reason: 'Production must read SUPABASE_ANON_KEY from environment',
        );

        expect(
          source.contains("fromEnvironment('SUPABASE_ANON_KEY', defaultValue:"),
          isFalse,
          reason: 'Production must NOT have defaultValue for SUPABASE_ANON_KEY',
        );

        // Check for any hardcoded JWT-like strings
        expect(
          source.contains('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'),
          isFalse,
          reason: 'Production must NOT hardcode Supabase anon key',
        );
      },
    );

    test('Production main_prod.dart throws on MOCK_MODE=true', () async {
      final filePath = path.join('lib', 'main_prod.dart');
      final source = await File(filePath).readAsString();

      // Must use bool.fromEnvironment for MOCK_MODE
      expect(
        source.contains('bool.fromEnvironment'),
        isTrue,
        reason: 'Production must use bool.fromEnvironment for MOCK_MODE',
      );
      expect(
        source.contains('MOCK_MODE'),
        isTrue,
        reason: 'Production must check MOCK_MODE',
      );

      // Must also check BACKEND_MODE
      expect(
        source.contains('BACKEND_MODE'),
        isTrue,
        reason: 'Production must check BACKEND_MODE',
      );

      // Must assert it's false (quote-agnostic)
      expect(
        source.contains('MOCK_MODE must be false in production builds'),
        isTrue,
        reason: 'Production must assert MOCK_MODE is false',
      );

      // Must throw StateError on violation (quote-agnostic)
      expect(
        source.contains('throw StateError'),
        isTrue,
        reason: 'Production must throw StateError on MOCK_MODE violation',
      );
      expect(
        source.contains('Security violation'),
        isTrue,
        reason: 'Production must mention Security violation in error message',
      );
    });

    test('Production requires dart defines for Supabase config', () async {
      final filePath = path.join('lib', 'main_prod.dart');
      final source = await File(filePath).readAsString();

      // All three Supabase-related configs must use fromEnvironment without defaults
      expect(source.contains("fromEnvironment('SUPABASE_URL')"), isTrue);
      expect(source.contains("fromEnvironment('SUPABASE_ANON_KEY')"), isTrue);
      expect(source.contains("fromEnvironment('STRIPE_KEY_PROD')"), isTrue);

      // Count total fromEnvironment calls - should be at least 3
      final envVars = RegExp(
        r"fromEnvironment\('([^']+)'\)",
      ).allMatches(source);
      expect(
        envVars.length >= 3,
        isTrue,
        reason: 'Production must use fromEnvironment for all external configs',
      );
    });
  });

  group('Supabase Filter Regression Tests - Edge Functions', () {
    test('Edge functions have Prefer header for SELECT queries', () async {
      // Check twilio_masked_call
      final twilioPath = path.join(
        'supabase',
        'functions',
        'twilio_masked_call',
        'index.ts',
      );
      if (await File(twilioPath).exists()) {
        final source = await File(twilioPath).readAsString();
        expect(
          source.contains("'Prefer': 'return=representation'"),
          isTrue,
          reason: 'twilio_masked_call must have Prefer header',
        );
      }

      // Check stripe_webhook
      final stripePath = path.join(
        'supabase',
        'functions',
        'stripe_webhook',
        'index.ts',
      );
      if (await File(stripePath).exists()) {
        final source = await File(stripePath).readAsString();
        expect(
          source.contains("'Prefer': 'return=representation'"),
          isTrue,
          reason: 'stripe_webhook must have Prefer header',
        );
      }
    });
  });
}
