import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../models/user_model.dart';

class AuthRepository {
  final ApiService _apiService;
  final LocalStorageService _storage;
  final FirebaseAuth? _firebaseAuth;

  AuthRepository(this._apiService, this._storage, {FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? (Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null);

  /// Authenticate user with WordPress JWT plugin
  Future<bool> login(String username, String password) async {
    try {
      final response = await _apiService.post(
        '/wp-json/jwt-auth/v1/token',
        data: {
          'username': username,
          'password': password,
        },
      );

      final token = response['token'] as String?;
      if (token != null) {
        await _storage.saveToken(token);
        
        // Optional Firebase Auth Fallback
        try {
          await _firebaseAuth?.signInWithEmailAndPassword(
            email: username, // Assuming username is email
            password: password,
          );
        } catch (e) {
          // Ignore firebase errors
        }

        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Logout user by removing token
  Future<void> logout() async {
    await _storage.deleteToken();
    try {
      await _firebaseAuth?.signOut();
    } catch (e) {
      // Ignore firebase errors
    }
  }

  /// Check if user has stored token
  Future<bool> isAuthenticated() async {
    final token = await _storage.getToken();
    return token != null && token.isNotEmpty && token != 'null';
  }

  /// Get current user profile
  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await _apiService.get('/wp-json/wp/v2/users/me');
      if (response != null && response is Map<String, dynamic>) {
        return UserModel.fromJson(response);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
