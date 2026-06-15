import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../models/user_model.dart';

class AuthRepository {
  final SupabaseClient _supabase;
  final LocalStorageService _storage;

  AuthRepository(this._supabase, this._storage);

  /// Authenticate user with Supabase Auth
  Future<bool> login(String username, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: username, // Assuming username is email in Supabase
        password: password,
      );

      final session = response.session;
      if (session != null) {
        await _storage.saveToken(session.accessToken);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Authenticate user with Supabase Google OAuth
  Future<UserModel?> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(OAuthProvider.google);
      // For web popups or mobile redirects, the auth state change will be picked up separately,
      // but we try to return the user if it's already available.
      return await getCurrentUser();
    } catch (e) {
      rethrow;
    }
  }

  /// Logout user
  Future<void> logout() async {
    await _storage.deleteToken();
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      // Ignore errors
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return _supabase.auth.currentSession != null;
  }

  /// Get current user profile
  Future<UserModel?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return null;
    }
    return _userModelFromSupabaseUser(user);
  }

  UserModel _userModelFromSupabaseUser(User user) {
    final email = user.email ?? '';
    final metadata = user.userMetadata ?? {};
    
    final name = metadata['full_name'] ?? metadata['name'] ?? email;
    final avatarUrl = metadata['avatar_url'] ?? metadata['picture'];

    return UserModel(
      id: user.id,
      name: name,
      email: email,
      profilePictureUrl: avatarUrl,
      role: 'customer',
      isActive: true,
    );
  }
}
