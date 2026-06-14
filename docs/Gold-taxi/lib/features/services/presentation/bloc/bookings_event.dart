import 'package:equatable/equatable.dart';

abstract class BookingsEvent extends Equatable {
  const BookingsEvent();

  @override
  List<Object?> get props => [];
}

class FetchAvailableSlots extends BookingsEvent {
  final int serviceId;
  final String date;

  const FetchAvailableSlots({required this.serviceId, required this.date});

  @override
  List<Object?> get props => [serviceId, date];
}

class SubmitBooking extends BookingsEvent {
  final int serviceId;
  final String date;
  final String timeSlot;

  const SubmitBooking({
    required this.serviceId,
    required this.date,
    required this.timeSlot,
  });

  @override
  List<Object?> get props => [serviceId, date, timeSlot];
}
