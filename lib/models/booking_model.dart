import 'package:equatable/equatable.dart';

class BookingModel extends Equatable {
  final int id;
  final int serviceId;
  final DateTime bookingDate;
  final String timeSlot;
  final String status;

  const BookingModel({
    required this.id,
    required this.serviceId,
    required this.bookingDate,
    required this.timeSlot,
    required this.status,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final jetMeta = json['jet_engine_meta'] as Map<String, dynamic>? ?? {};
    final acf = json['acf'] as Map<String, dynamic>? ?? {};

    T getField<T>(String key, T defaultValue) {
      return (json[key] ?? meta[key] ?? jetMeta[key] ?? acf[key]) as T? ?? defaultValue;
    }

    dynamic rawServiceId = getField<dynamic>('service_id', 0);
    int serviceId = rawServiceId is int ? rawServiceId : (int.tryParse(rawServiceId.toString()) ?? 0);

    String rawDate = getField<String>('booking_date', '');
    if (rawDate.isEmpty) {
      rawDate = json['date'] as String? ?? '';
    }

    String status = getField<String>('status', 'pending');
    if (status == 'pending' && json['post_status'] != null) {
      status = json['post_status'] as String;
    }

    return BookingModel(
      id: json['id'] as int? ?? 0,
      serviceId: serviceId,
      bookingDate: DateTime.tryParse(rawDate) ?? DateTime.now(),
      timeSlot: getField<String>('time_slot', ''),
      status: status,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'service_id': serviceId,
    'booking_date': bookingDate.toIso8601String(),
    'time_slot': timeSlot,
    'status': status,
  };

  @override
  List<Object?> get props => [id, serviceId, bookingDate, timeSlot, status];
}
