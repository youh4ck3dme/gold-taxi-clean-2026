import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:gold_taxi/models/booking_model.dart';
import '../datasources/bookings_remote_datasource.dart';

class BookingsRepository {
  final BookingsRemoteDataSource _remoteDataSource;
  final Connectivity _connectivity;

  // List of all business hours slots
  static const List<String> _allTimeSlots = [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
  ];

  BookingsRepository(this._remoteDataSource, this._connectivity);

  /// Fetch all available (free) time slots for a service on a given date
  Future<List<String>> getAvailableSlots(int serviceId, String date) async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return []; // Bookings require internet
    }

    try {
      final bookedSlots = await _remoteDataSource.fetchBookedSlots(
        serviceId,
        date,
      );
      // Filter out already booked slots
      return _allTimeSlots
          .where((slot) => !bookedSlots.contains(slot))
          .toList();
    } catch (_) {
      return _allTimeSlots; // Return all on failure or return empty depending on API strictness
    }
  }

  /// Create a new service booking
  Future<BookingModel> bookSlot({
    required int serviceId,
    required String date,
    required String timeSlot,
  }) async {
    return await _remoteDataSource.createBooking(
      serviceId: serviceId,
      date: date,
      timeSlot: timeSlot,
    );
  }
}
