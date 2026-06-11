import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/bookings_repository.dart';
import 'bookings_event.dart';
import 'bookings_state.dart';

class BookingsBloc extends Bloc<BookingsEvent, BookingsState> {
  final BookingsRepository _bookingsRepository;

  BookingsBloc(this._bookingsRepository) : super(BookingsInitial()) {
    on<FetchAvailableSlots>(_onFetchAvailableSlots);
    on<SubmitBooking>(_onSubmitBooking);
  }

  Future<void> _onFetchAvailableSlots(FetchAvailableSlots event, Emitter<BookingsState> emit) async {
    emit(BookingsLoading());
    try {
      final slots = await _bookingsRepository.getAvailableSlots(event.serviceId, event.date);
      emit(BookingsSlotsLoaded(availableSlots: slots));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onSubmitBooking(SubmitBooking event, Emitter<BookingsState> emit) async {
    emit(BookingSubmissionInProgress());
    try {
      final booking = await _bookingsRepository.bookSlot(
        serviceId: event.serviceId,
        date: event.date,
        timeSlot: event.timeSlot,
      );
      emit(BookingSubmissionSuccess(booking: booking));
    } catch (e) {
      emit(BookingSubmissionFailure(e.toString()));
    }
  }
}
