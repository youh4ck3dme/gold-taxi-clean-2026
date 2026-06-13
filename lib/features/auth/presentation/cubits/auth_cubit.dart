import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../models/user_model.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit(this._authRepository) : super(AuthInitial());

  /// Check token status on startup
  Future<void> checkAuthStatus() async {
    emit(AuthLoading());
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
  }

  /// Login action
  Future<void> login(String username, String password) async {
    emit(AuthLoading());
    final success = await _authRepository.login(username, password);
    if (success) {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const AuthError('Failed to load user profile.'));
        emit(Unauthenticated());
      }
    } else {
      emit(const AuthError('Login failed. Please check your credentials.'));
      emit(Unauthenticated());
    }
  }

  /// Google Sign-In action
  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    final user = await _authRepository.signInWithGoogle();
    if (user != null) {
      emit(Authenticated(user));
    } else {
      emit(const AuthError('Google prihlásenie zlyhalo.'));
      emit(Unauthenticated());
    }
  }

  /// 🔧 DEVELOPER BYPASS — skip auth, go straight to home
  void developerBypass() {
    const devUser = UserModel(
      id: 0,
      name: 'Developer',
      email: 'dev@localhost',
      role: 'administrator',
      isActive: true,
    );
    emit(const Authenticated(devUser));
  }

  /// Logout action
  Future<void> logout() async {
    emit(AuthLoading());
    await _authRepository.logout();
    emit(Unauthenticated());
  }
}
