import 'package:flutter_test/flutter_test.dart';
import 'package:gold_taxi/auth/auth_repository.dart';

void main() {
  group('UserProfile Tests', () {
    test('fromMap: Úspešné vytvorenie', () {
      final map = {
        'id': 'user-id',
        'email': 'test@example.com',
        'role': 'driver',
        'full_name': 'Test Driver',
      };
      final userProfile = UserProfile.fromMap(map);
      expect(userProfile.id, 'user-id');
      expect(userProfile.email, 'test@example.com');
      expect(userProfile.role, 'driver');
      expect(userProfile.fullName, 'Test Driver');
    });

    test('fromMap: Default hodnoty', () {
      final userProfile = UserProfile.fromMap({});
      expect(userProfile.id, '');
      expect(userProfile.email, '');
      expect(userProfile.role, 'customer');
      expect(userProfile.fullName, '');
    });
  });
}
