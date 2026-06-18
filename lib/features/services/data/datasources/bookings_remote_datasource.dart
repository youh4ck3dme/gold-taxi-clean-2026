import 'package:gold_taxi/core/constants/api_constants.dart';
import 'package:gold_taxi/core/services/api_service.dart';
import 'package:gold_taxi/models/booking_model.dart';

class BookingsRemoteDataSource {
  final ApiService _apiService;

  BookingsRemoteDataSource(this._apiService);

  /// Fetch already booked time slots for a service on a given date
  Future<List<String>> fetchBookedSlots(int serviceId, String date) async {
    final response = await _apiService.get(
      ApiConstants.bookingsEndpoint,
      queryParameters: {'service_id': serviceId, 'date': date},
    );

    if (response is List) {
      return response.map((item) => item['time_slot'] as String).toList();
    }
    return [];
  }

  /// Create a new booking
  Future<BookingModel> createBooking({
    required int serviceId,
    required String date,
    required String timeSlot,
  }) async {
    final response = await _apiService.post(
      ApiConstants.bookingsEndpoint,
      data: {
        'service_id': serviceId,
        'booking_date': date,
        'time_slot': timeSlot,
      },
    );

    return BookingModel.fromJson(response as Map<String, dynamic>);
  }
}
