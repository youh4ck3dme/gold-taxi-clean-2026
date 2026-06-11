import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository(),
        super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final userProfile = await _authRepository.getCurrentUser();
      if (userProfile != null) {
        emit(Authenticated(userProfile));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError('Chyba pri inicializácii: ${e.toString()}'));
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final userProfile = await _authRepository.login(event.email, event.password);
      if (userProfile != null) {
        emit(Authenticated(userProfile));
      } else {
        emit(const AuthError('Prihlásenie zlyhalo.'));
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(Unauthenticated());
    }
  }

  Future<void> _onRegisterRequested(RegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final userProfile = await _authRepository.register(
        email: event.email,
        password: event.password,
        fullName: event.fullName,
        role: event.role,
      );
      if (userProfile != null) {
        emit(Authenticated(userProfile));
      } else {
        emit(const AuthError('Registrácia zlyhala.'));
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(Unauthenticated());
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.logout();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
