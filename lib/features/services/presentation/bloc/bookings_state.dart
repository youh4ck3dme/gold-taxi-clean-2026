import 'package:equatable/equatable.dart';
import 'package:gold_taxi/models/booking_model.dart';

abstract class BookingsState extends Equatable {
  const BookingsState();

  @override
  List<Object?> get props => [];
}

class BookingsInitial extends BookingsState {}

class BookingsLoading extends BookingsState {}

class BookingsSlotsLoaded extends BookingsState {
  final List<String> availableSlots;

  const BookingsSlotsLoaded({required this.availableSlots});

  @override
  List<Object?> get props => [availableSlots];
}

class BookingsError extends BookingsState {
  final String message;

  const BookingsError(this.message);

  @override
  List<Object?> get props => [message];
}

class BookingSubmissionInProgress extends BookingsState {}

class BookingSubmissionSuccess extends BookingsState {
  final BookingModel booking;

  const BookingSubmissionSuccess({required this.booking});

  @override
  List<Object?> get props => [booking];
}

class BookingSubmissionFailure extends BookingsState {
  final String message;

  const BookingSubmissionFailure(this.message);

  @override
  List<Object?> get props => [message];
}
