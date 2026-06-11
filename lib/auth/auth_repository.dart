import 'package:supabase_flutter/supabase_flutter.dart';

/// Model pre používateľský profil z tabuľky `profiles`
class UserProfile {
  final String id;
  final String email;
  final String role;
  final String fullName;

  UserProfile({
    required this.id,
    required this.email,
    required this.role,
    required this.fullName,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'customer',
      fullName: map['full_name'] ?? '',
    );
  }
}

/// Repository pre autentifikáciu a správu používateľov
class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  /// Prihlásenie používateľa cez email a heslo
  Future<UserProfile?> login(String email, String password) async {
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Prihlásenie zlyhalo: Nesprávny email alebo heslo');
      }

      // Načítanie roly z tabuľky `profiles`
      final profileData = await _supabase
          .from('profiles')
          .select()
          .eq('email', email)
          .single();

      return UserProfile.fromMap(profileData);
    } catch (e) {
      throw Exception('Chyba pri prihlásení: ${e.toString()}');
    }
  }

  /// Registrácia nového používateľa
  Future<UserProfile?> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      // Vytvorenie používateľa v Supabase Auth
      final AuthResponse authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Registrácia zlyhala');
      }

      // Vloženie profilu do tabuľky `profiles`
      final profileData = {
        'id': authResponse.user!.id,
        'email': email,
        'role': role,
        'full_name': fullName,
      };

      await _supabase.from('profiles').insert(profileData);

      // Načítanie a vrátenie profilu
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('email', email)
          .single();

      return UserProfile.fromMap(profile);
    } catch (e) {
      throw Exception('Chyba pri registrácii: ${e.toString()}');
    }
  }

  /// Odhlásenie používateľa
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  /// Získanie aktuálne prihláseného používateľa
  Future<UserProfile?> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('email', user.email!)
          .single();

      return UserProfile.fromMap(profile);
    } catch (e) {
      return null;
    }
  }
}
