import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../models/user_model.dart';

class AuthRepository {
  final LocalStorageService _storage;
  final SupabaseClient _supabaseClient;

  AuthRepository(
    this._storage, {
    SupabaseClient? supabaseClient,
  }) : _supabaseClient = supabaseClient ?? Supabase.instance.client;

  /// Authenticate user with Supabase Auth
  Future<bool> login(String email, String password) async {
    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return response.user != null;
    } catch (e) {
      rethrow;
    }
  }

  /// Authenticate user with Supabase Google Sign-In
  Future<UserModel?> signInWithGoogle() async {
    try {
      final success = await _supabaseClient.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.goldtaxi://login-callback/',
      );
      if (!success) {
        throw Exception('Supabase Google Sign-In initiation failed.');
      }
      final user = _supabaseClient.auth.currentUser;
      if (user != null) {
        return await getCurrentUser();
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Logout user from Supabase and clear local storage token
  Future<void> logout() async {
    await _storage.deleteToken();
    try {
      await _supabaseClient.auth.signOut();
    } catch (_) {
      // Ignore errors during logout
    }
  }

  /// Check if user session exists in Supabase
  Future<bool> isAuthenticated() async {
    return _supabaseClient.auth.currentSession != null;
  }

  /// Get current user profile from Supabase profiles table where id == auth.uid()
  Future<UserModel?> getCurrentUser() async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      return null;
    }

    try {
      final response = await _supabaseClient
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      return UserModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}

