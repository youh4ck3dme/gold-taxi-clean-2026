import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../models/user_model.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit(this._authRepository) : super(AuthInitial());

  /// Check token status on startup
  Future<void> checkAuthStatus() async {
    emit(AuthLoading());
    try {
      final hasToken = await _authRepository.isAuthenticated();
      if (hasToken) {
        final user = await _authRepository.getCurrentUser();
        if (user != null) {
          emit(Authenticated(user));
        } else {
          emit(Unauthenticated());
        }
      } else {
        emit(Unauthenticated());
      }
    } catch (_) {
      emit(Unauthenticated());
    }
  }

  /// Login action
  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final success = await _authRepository.login(email, password);
      if (success) {
        final user = await _authRepository.getCurrentUser();
        if (user != null) {
          emit(Authenticated(user));
        } else {
          emit(const AuthError('Nepodarilo sa načítať profil používateľa.'));
          emit(Unauthenticated());
        }
      } else {
        emit(const AuthError('Prihlásenie zlyhalo. Skontrolujte si údaje.'));
        emit(Unauthenticated());
      }
    } on AuthException catch (e) {
      emit(AuthError('Prihlásenie zlyhalo: ${e.message}'));
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError('Prihlásenie zlyhalo: $e'));
      emit(Unauthenticated());
    }
  }

  /// Google Sign-In action
  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signInWithGoogle();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const AuthError('Google prihlásenie zlyhalo (Používateľ nebol nájdený).'));
        emit(Unauthenticated());
      }
    } on AuthException catch (e) {
      emit(AuthError('Google prihlásenie zlyhalo: [${e.code}] ${e.message}'));
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError('Google prihlásenie zlyhalo: $e'));
      emit(Unauthenticated());
    }
  }

  /// Logout action
  Future<void> logout() async {
    emit(AuthLoading());
    await _authRepository.logout();
    emit(Unauthenticated());
  }
}

