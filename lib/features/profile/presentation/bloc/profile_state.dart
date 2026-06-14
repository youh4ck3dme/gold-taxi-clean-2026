import 'package:equatable/equatable.dart';
import 'package:gold_taxi/models/user_model.dart';


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
  final List<dynamic> bookings;
  final Map<String, dynamic>? driverRecord;
  final Map<String, dynamic>? driverStats;
  final String activeRole; // 'customer' or 'driver'

  const ProfileLoaded({
    required this.user,
    required this.orders,
    required this.bookings,
    this.driverRecord,
    this.driverStats,
    this.activeRole = 'customer',
  });

  int get loyaltyPoints {
    // 10 loyalty points per completed order
    final orderPoints = orders.where((order) => order['status'] == 'completed').length * 10;
    // Add 5 points per booking
    final bookingPoints = bookings.length * 5;
    return orderPoints + bookingPoints;
  }

  ProfileLoaded copyWith({
    UserModel? user,
    List<Map<String, dynamic>>? orders,
    List<dynamic>? bookings,
    Map<String, dynamic>? driverRecord,
    Map<String, dynamic>? driverStats,
    String? activeRole,
  }) {
    return ProfileLoaded(
      user: user ?? this.user,
      orders: orders ?? this.orders,
      bookings: bookings ?? this.bookings,
      driverRecord: driverRecord ?? this.driverRecord,
      driverStats: driverStats ?? this.driverStats,
      activeRole: activeRole ?? this.activeRole,
    );
  }

  @override
  List<Object?> get props => [user, orders, bookings, driverRecord, driverStats, activeRole];
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

