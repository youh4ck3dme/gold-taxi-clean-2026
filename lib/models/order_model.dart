import 'package:equatable/equatable.dart';

class OrderModel extends Equatable {
  final int id;
  final String status;
  final String total;
  final String currency;
  final DateTime dateCreated;
  final List<String> items;

  const OrderModel({
    required this.id,
    required this.status,
    required this.total,
    required this.currency,
    required this.dateCreated,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as int,
      status: json['status'] as String? ?? 'unknown',
      total: json['total'] as String? ?? '0.00',
      currency: json['currency'] as String? ?? 'EUR',
      dateCreated: DateTime.parse(json['date_created'] as String),
      items:
          (json['line_items'] as List<dynamic>?)
              ?.map((item) => item['name'] as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'total': total,
      'currency': currency,
      'date_created': dateCreated.toIso8601String(),
      'line_items': items.map((name) => {'name': name}).toList(),
    };
  }

  @override
  List<Object?> get props => [id, status, total, currency, dateCreated, items];
}
