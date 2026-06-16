import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../models/user_model.dart';

abstract class AuthRepository {
  Future<bool> login(String username, String password);
  Future<UserModel?> signInWithGoogle();
  Future<void> logout();
  Future<bool> isAuthenticated();
  Future<UserModel?> getCurrentUser();
}

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _supabase;
  final LocalStorageService _storage;

  SupabaseAuthRepository(this._supabase, this._storage);

  @override
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

  @override
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

  @override
  Future<void> logout() async {
    await _storage.deleteToken();
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      // Ignore errors
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return _supabase.auth.currentSession != null;
  }

  @override
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

class MockAuthRepository implements AuthRepository {
  final LocalStorageService _storage;

  MockAuthRepository(this._storage);

  @override
  Future<bool> login(String username, String password) async {
    await _storage.saveToken("mock_token_value");
    return true;
  }

  @override
  Future<UserModel?> signInWithGoogle() async {
    await _storage.saveToken("mock_google_token_value");
    return getCurrentUser();
  }

  @override
  Future<void> logout() async {
    await _storage.deleteToken();
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await _storage.getToken();
    return token != null;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final token = await _storage.getToken();
    if (token == null) {
      return null;
    }
    return const UserModel(
      id: "mock-user-id",
      name: "Mock Taxi Admin",
      email: "admin@goldtaxi.sk",
      profilePictureUrl: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=150",
      role: "admin",
      isActive: true,
    );
  }
}
