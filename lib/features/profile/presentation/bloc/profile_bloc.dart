import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _profileRepository;

  ProfileBloc(this._profileRepository) : super(ProfileInitial()) {
    on<FetchProfile>(_onFetchProfile);
    on<UpdateProfile>(_onUpdateProfile);
  }

  Future<void> _onFetchProfile(FetchProfile event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    try {
      final user = await _profileRepository.getUserProfile();
      final orders = await _profileRepository.getOrderHistory(user.id);
      final bookings = await _profileRepository.getBookingHistory(user.id);
      emit(ProfileLoaded(user: user, orders: orders, bookings: bookings));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onUpdateProfile(UpdateProfile event, Emitter<ProfileState> emit) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      emit(ProfileUpdating());
      try {
        final updatedUser = await _profileRepository.updateUserProfile(
          name: event.name,
          bio: event.bio,
        );
        // Re-fetch orders/bookings with new user data
        final orders = await _profileRepository.getOrderHistory(updatedUser.id);
        final bookings = await _profileRepository.getBookingHistory(updatedUser.id);
        emit(ProfileLoaded(user: updatedUser, orders: orders, bookings: bookings));
      } catch (e) {
        emit(ProfileError(e.toString()));
      }
    }
  }
}
