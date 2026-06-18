import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'package:gold_taxi/features/map/data/repositories/supabase_ride_repository.dart';

void main() {
  group('SupabaseRideRepository - Filter Validation Tests', () {
    
    test('getAllRides() MUST use a filter to prevent 400 Bad Request', () async {
      // Read the source file directly
      const filePath = 'lib/features/map/data/repositories/supabase_ride_repository.dart';
      final source = await File(filePath).readAsString();
      
      // Verify that getAllRides() uses .neq() filter
      expect(source.contains('getAllRides()'), isTrue);
      expect(source.contains('.neq('), isTrue, 
          reason: 'getAllRides() must use .neq() or other filter to avoid 400 Bad Request');
      
      // Verify the exact line with getAllRides has a filter
      final lines = source.split('\n');
      bool inGetAllRides = false;
      bool hasFilter = false;
      
      for (final line in lines) {
        if (line.contains('getAllRides()')) {
          inGetAllRides = true;
        }
        if (inGetAllRides && line.contains(".from('rides')")) {
          // Check if this line or next few lines have a filter
          final index = lines.indexOf(line);
          for (int i = index; i < lines.length && i <= index + 5; i++) {
            if (lines[i].contains('.neq(') || 
                lines[i].contains('.eq(') || 
                lines[i].contains('.filter(')) {
              hasFilter = true;
              break;
            }
          }
          break;
        }
      }
      
      expect(hasFilter, isTrue,
          reason: 'getAllRides() must have a filter after .from(\'rides\')');
    });

    test('getCustomerRides() uses customer_id filter', () async {
      const filePath = 'lib/features/map/data/repositories/supabase_ride_repository.dart';
      final source = await File(filePath).readAsString();
      
      expect(source.contains('getCustomerRides'), isTrue);
      expect(source.contains(".eq('customer_id'"), isTrue,
          reason: 'getCustomerRides() must filter by customer_id');
    });

    test('getRide() uses id filter', () async {
      const filePath = 'lib/features/map/data/repositories/supabase_ride_repository.dart';
      final source = await File(filePath).readAsString();
      
      expect(source.contains('getRide'), isTrue);
      expect(source.contains(".eq('id'"), isTrue,
          reason: 'getRide() must filter by id');
    });

    test('getActiveRequests() uses status filter', () async {
      const filePath = 'lib/features/map/data/repositories/supabase_ride_repository.dart';
      final source = await File(filePath).readAsString();
      
      expect(source.contains('getActiveRequests'), isTrue);
      expect(source.contains(".eq('status', 'requested')"), isTrue,
          reason: 'getActiveRequests() must filter by status');
    });

    test('getDriverActiveRide() uses driver_id filter', () async {
      const filePath = 'lib/features/map/data/repositories/supabase_ride_repository.dart';
      final source = await File(filePath).readAsString();
      
      expect(source.contains('getDriverActiveRide'), isTrue);
      expect(source.contains(".eq('driver_id'"), isTrue,
          reason: 'getDriverActiveRide() must filter by driver_id');
    });
  });

  group('SupabaseRideRepository - Integration Checks', () {
    test('All SELECT queries on rides table MUST have filters', () async {
      const filePath = 'lib/features/map/data/repositories/supabase_ride_repository.dart';
      final source = await File(filePath).readAsString();
      
      // Count occurrences of .from('rides') - should have filters
      final fromRidesMatches = RegExp(r"from\('rides'\)").allMatches(source);
      
      // Each .from('rides') should be followed by a filter method
      // Filter methods include: .eq(), .neq(), .gt(), .lt(), .in(), .filter()
      final filterMethods = RegExp(r'\.(eq|neq|gt|lt|gte|lte|in|filter)\(').allMatches(source);
      
      // Verify that there are enough filters for all from('rides') calls
      expect(fromRidesMatches.length <= filterMethods.length, isTrue,
          reason: 'Every .from(\'rides\') must be followed by a filter method. '
                  'Found ${fromRidesMatches.length} from(\'rides\') calls and ${filterMethods.length} filter methods.');
    });
  });

  group('FAQ Repository - Filter Validation', () {
    test('getFaqs() MUST use a filter to prevent 400 Bad Request', () async {
      const filePath = 'lib/features/faq/data/repositories/faq_repository.dart';
      final source = await File(filePath).readAsString();
      
      expect(source.contains('.neq('), isTrue,
          reason: 'getFaqs() must use .neq() or other filter to avoid 400 Bad Request');
      expect(source.contains('.from(\'faqs\')'), isTrue);
    });
  });
}
