import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/profile_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _profileRepository;

  ProfileCubit(this._profileRepository) : super(ProfileInitial());

  Future<void> fetchProfile() async {
    emit(ProfileLoading());
    try {
      final user = await _profileRepository.getUserProfile();
      final orders = await _profileRepository.getOrderHistory(user.id);
      final bookings = await _profileRepository.getBookingHistory(user.id);

      Map<String, dynamic>? driverRecord;
      Map<String, dynamic>? driverStats;
      if (user.isDriver) {
        driverRecord = await _profileRepository.getDriverRecord(user.id);
        if (driverRecord != null) {
          final driverId = driverRecord['id'] as String;
          driverStats = await _profileRepository.getDriverStats(driverId);
        }
      }

      emit(ProfileLoaded(
        user: user,
        orders: orders,
        bookings: bookings,
        driverRecord: driverRecord,
        driverStats: driverStats,
        activeRole: user.isDriver ? 'driver' : 'customer',
      ));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  void switchRole(String newRole) {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      if (newRole == 'driver' && !currentState.user.isDriver) return;
      emit(currentState.copyWith(activeRole: newRole));
    }
  }

  Future<void> updateCustomerProfile({
    required String fullName,
    required String phone,
    required Map<String, dynamic> savedAddresses,
  }) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      emit(ProfileUpdating());
      try {
        final updatedUser = await _profileRepository.updateCustomerProfile(
          fullName: fullName,
          phone: phone,
          savedAddresses: savedAddresses,
        );
        emit(ProfileLoaded(
          user: updatedUser,
          orders: currentState.orders,
          bookings: currentState.bookings,
          driverRecord: currentState.driverRecord,
        ));
      } catch (e) {
        emit(ProfileError(e.toString()));
      }
    }
  }

  Future<void> updateDriverProfile({
    required String vehicleType,
    required String vehiclePlate,
    required List<String> serviceClasses,
    required bool isOnline,
  }) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      emit(ProfileUpdating());
      try {
        await _profileRepository.updateDriverProfile(
          vehicleType: vehicleType,
          vehiclePlate: vehiclePlate,
          serviceClasses: serviceClasses,
          isOnline: isOnline,
        );
        // Refresh profile to update driver record
        final updatedDriverRecord = await _profileRepository.getDriverRecord(currentState.user.id);
        emit(ProfileLoaded(
          user: currentState.user,
          orders: currentState.orders,
          bookings: currentState.bookings,
          driverRecord: updatedDriverRecord,
          driverStats: currentState.driverStats,
        ));
      } catch (e) {
        emit(ProfileError(e.toString()));
      }
    }
  }
}
