import 'package:equatable/equatable.dart';
import 'package:gold_taxi/models/user_model.dart';
import 'package:gold_taxi/models/booking_model.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserModel user;
  final List<Map<String, dynamic>> orders;
  final List<BookingModel> bookings;

  const ProfileLoaded({
    required this.user,
    required this.orders,
    required this.bookings,
  });

  int get loyaltyPoints {
    // 10 loyalty points per completed order
    return orders.where((order) => order['status'] == 'completed').length * 10;
  }

  @override
  List<Object?> get props => [user, orders, bookings];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProfileUpdating extends ProfileState {}

class ProfileUpdateSuccess extends ProfileState {
  final UserModel updatedUser;

  const ProfileUpdateSuccess(this.updatedUser);

  @override
  List<Object?> get props => [updatedUser];
}
