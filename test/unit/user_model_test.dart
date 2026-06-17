import 'package:flutter_test/flutter_test.dart';
import 'package:gold_taxi/models/user_model.dart';

void main() {
  group('UserModel URL Sanitization Tests', () {
    test('should return null when url is empty', () {
      final user = UserModel.fromJson(const {
        'id': '1',
        'name': 'Erik',
        'email': 'erik@example.com',
        'role': 'customer',
        'profile_picture_url': '',
      });
      expect(user.profilePictureUrl, isNull);
    });

    test('should return null when url is "null"', () {
      final user = UserModel.fromJson(const {
        'id': '1',
        'name': 'Erik',
        'email': 'erik@example.com',
        'role': 'customer',
        'profile_picture_url': 'null',
      });
      expect(user.profilePictureUrl, isNull);
    });

    test('should return null when url contains spaces or is empty string', () {
      final user = UserModel.fromJson(const {
        'id': '1',
        'name': 'Erik',
        'email': 'erik@example.com',
        'role': 'customer',
        'profile_picture_url': '   ',
      });
      expect(user.profilePictureUrl, isNull);
    });

    test('should return url when url is valid', () {
      final user = UserModel.fromJson(const {
        'id': '1',
        'name': 'Erik',
        'email': 'erik@example.com',
        'role': 'customer',
        'profile_picture_url': 'https://example.com/profile.jpg',
      });
      expect(user.profilePictureUrl, 'https://example.com/profile.jpg');
    });
  });
}
