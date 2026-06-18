import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(SplashInitial());

  Future<void> initializeApp() async {
    emit(SplashLoading());

    try {
      // App initialization is already done in main_common.dart
      // Here we just wait for the splash video (3.2 seconds)
      await Future.delayed(const Duration(milliseconds: 3200));
      emit(SplashCompleted());
    } catch (e) {
      emit(SplashError(message: e.toString()));
    }
  }
}
