import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gold_taxi/features/services/presentation/bloc/bookings_bloc.dart';
import 'package:gold_taxi/features/services/presentation/bloc/bookings_event.dart';
import 'package:gold_taxi/features/services/presentation/bloc/bookings_state.dart';
import 'package:gold_taxi/features/services/data/repositories/bookings_repository.dart';
import 'package:gold_taxi/models/booking_model.dart';

class MockBookingsRepository extends Mock implements BookingsRepository {}

void main() {
  late BookingsBloc bookingsBloc;
  late MockBookingsRepository mockBookingsRepository;

  setUp(() {
    mockBookingsRepository = MockBookingsRepository();
    bookingsBloc = BookingsBloc(mockBookingsRepository);
  });

  tearDown(() {
    bookingsBloc.close();
  });

  group('BookingsBloc Tests', () {
    final testBooking = BookingModel(
      id: 1,
      serviceId: 2,
      bookingDate: DateTime(2026, 6, 12),
      timeSlot: '14:00',
      status: 'confirmed',
    );

    test('Initial state is BookingsInitial', () {
      expect(bookingsBloc.state, isA<BookingsInitial>());
    });

    test(
      'FetchAvailableSlots emits [BookingsLoading, BookingsSlotsLoaded] when repository succeeds',
      () async {
        when(
          () => mockBookingsRepository.getAvailableSlots(any(), any()),
        ).thenAnswer((_) async => ['14:00', '15:00']);

        expectLater(
          bookingsBloc.stream,
          emitsInOrder([isA<BookingsLoading>(), isA<BookingsSlotsLoaded>()]),
        );

        bookingsBloc.add(
          const FetchAvailableSlots(serviceId: 2, date: '2026-06-12'),
        );
      },
    );

    test(
      'FetchAvailableSlots emits [BookingsLoading, BookingsError] when repository throws error',
      () async {
        when(
          () => mockBookingsRepository.getAvailableSlots(any(), any()),
        ).thenThrow(Exception('API error'));

        expectLater(
          bookingsBloc.stream,
          emitsInOrder([isA<BookingsLoading>(), isA<BookingsError>()]),
        );

        bookingsBloc.add(
          const FetchAvailableSlots(serviceId: 2, date: '2026-06-12'),
        );
      },
    );

    test(
      'SubmitBooking emits [BookingSubmissionInProgress, BookingSubmissionSuccess] when repository succeeds',
      () async {
        when(
          () => mockBookingsRepository.bookSlot(
            serviceId: any(named: 'serviceId'),
            date: any(named: 'date'),
            timeSlot: any(named: 'timeSlot'),
          ),
        ).thenAnswer((_) async => testBooking);

        expectLater(
          bookingsBloc.stream,
          emitsInOrder([
            isA<BookingSubmissionInProgress>(),
            isA<BookingSubmissionSuccess>(),
          ]),
        );

        bookingsBloc.add(
          const SubmitBooking(
            serviceId: 2,
            date: '2026-06-12',
            timeSlot: '14:00',
          ),
        );
      },
    );

    test(
      'SubmitBooking emits [BookingSubmissionInProgress, BookingSubmissionFailure] when repository fails',
      () async {
        when(
          () => mockBookingsRepository.bookSlot(
            serviceId: any(named: 'serviceId'),
            date: any(named: 'date'),
            timeSlot: any(named: 'timeSlot'),
          ),
        ).thenThrow(Exception('Booking failed'));

        expectLater(
          bookingsBloc.stream,
          emitsInOrder([
            isA<BookingSubmissionInProgress>(),
            isA<BookingSubmissionFailure>(),
          ]),
        );

        bookingsBloc.add(
          const SubmitBooking(
            serviceId: 2,
            date: '2026-06-12',
            timeSlot: '14:00',
          ),
        );
      },
    );
  });
}
