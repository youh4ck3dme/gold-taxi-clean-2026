import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../core/services/api_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../models/user_model.dart';

class AuthRepository {
  final ApiService _apiService;
  final LocalStorageService _storage;
  final FirebaseAuth? _firebaseAuth;
  final bool _isWeb;

  AuthRepository(
    this._apiService,
    this._storage, {
    FirebaseAuth? firebaseAuth,
    bool? isWeb,
  }) : _firebaseAuth =
           firebaseAuth ??
           (Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null),
       _isWeb = isWeb ?? kIsWeb;

  /// Authenticate user with WordPress JWT plugin
  Future<bool> login(String username, String password) async {
    try {
      final response = await _apiService.post(
        '/wp-json/jwt-auth/v1/token',
        data: {'username': username, 'password': password},
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

  /// Authenticate user with Firebase Google Sign-In on Web.
  Future<UserModel?> signInWithGoogle() async {
    final firebaseAuth = _firebaseAuth;
    if (firebaseAuth == null || !_isWeb) {
      return null;
    }

    try {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');
      final credential = await firebaseAuth.signInWithPopup(provider);
      final user = credential.user;
      if (user == null) {
        return null;
      }
      return _userModelFromFirebaseUser(user);
    } catch (e) {
      return null;
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
    if (token != null && token.isNotEmpty && token != 'null') {
      return true;
    }
    return _firebaseAuth?.currentUser != null;
  }

  /// Get current user profile
  Future<UserModel?> getCurrentUser() async {
    final token = await _storage.getToken();
    
    // Skip WordPress call if no token exists (Anonymous/Supabase-only mode)
    if (token == null || token.isEmpty || token == 'null') {
      final firebaseUser = _firebaseAuth?.currentUser;
      if (firebaseUser != null) {
        return _userModelFromFirebaseUser(firebaseUser);
      }
      return null;
    }

    try {
      final response = await _apiService.get('/wp-json/wp/v2/users/me');
      if (response != null && response is Map<String, dynamic>) {
        return UserModel.fromJson(response);
      }
      
      final firebaseUser = _firebaseAuth?.currentUser;
      return firebaseUser == null
          ? null
          : _userModelFromFirebaseUser(firebaseUser);
    } catch (e) {
      // If WordPress returns 401 or fails, clear invalid token and continue
      if (e.toString().contains('401')) {
        await _storage.deleteToken();
      }
      
      final firebaseUser = _firebaseAuth?.currentUser;
      return firebaseUser == null
          ? null
          : _userModelFromFirebaseUser(firebaseUser);
    }
  }

  UserModel _userModelFromFirebaseUser(User user) {
    final email = user.email ?? '';
    return UserModel(
      id: '0',
      name: user.displayName ?? email,
      email: email,
      profilePictureUrl: user.photoURL,
      role: 'customer',
      isActive: true,
    );
  }
}
