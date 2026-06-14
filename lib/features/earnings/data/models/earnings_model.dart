import 'package:equatable/equatable.dart';

/// Payment status for a ride earnings record
enum PaymentStatus {
  pending,
  completed,
  failed,
  refunded,
}

/// Payment method used for the ride
enum PaymentMethod {
  cash,
  card,
  stripe,
}

/// Model for driver earnings from a single ride
class EarningsModel extends Equatable {
  final String id;
  final String rideId;
  final String driverId;
  final double totalAmount;      // Total paid by customer
  final double appFee;           // Application fee (e.g., 15%)
  final double netAmount;        // Driver's net earnings
  final PaymentStatus paymentStatus;
  final PaymentMethod paymentMethod;
  final DateTime createdAt;

  const EarningsModel({
    required this.id,
    required this.rideId,
    required this.driverId,
    required this.totalAmount,
    required this.appFee,
    required this.netAmount,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.createdAt,
  });

  /// Create from JSON (Supabase)
  factory EarningsModel.fromJson(Map<String, dynamic> json) {
    return EarningsModel(
      id: json['id'] as String? ?? '',
      rideId: json['ride_id'] as String? ?? '',
      driverId: json['driver_id'] as String? ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      appFee: (json['app_fee'] as num?)?.toDouble() ?? 0.0,
      netAmount: (json['net_amount'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: _parsePaymentStatus(json['payment_status'] as String?),
      paymentMethod: _parsePaymentMethod(json['payment_method'] as String?),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ride_id': rideId,
      'driver_id': driverId,
      'total_amount': totalAmount,
      'app_fee': appFee,
      'net_amount': netAmount,
      'payment_status': paymentStatus.name,
      'payment_method': paymentMethod.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Helper to parse PaymentStatus
  static PaymentStatus _parsePaymentStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.pending;
    }
  }

  /// Helper to parse PaymentMethod
  static PaymentMethod _parsePaymentMethod(String? method) {
    switch (method?.toLowerCase()) {
      case 'card':
        return PaymentMethod.card;
      case 'stripe':
        return PaymentMethod.stripe;
      default:
        return PaymentMethod.cash;
    }
  }

  @override
  List<Object?> get props => [
    id,
    rideId,
    driverId,
    totalAmount,
    appFee,
    netAmount,
    paymentStatus,
    paymentMethod,
    createdAt,
  ];
}

/// Summary of driver earnings for different time periods
class EarningsSummary extends Equatable {
  final double today;
  final double thisWeek;
  final double thisMonth;
  final double total;

  const EarningsSummary({
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
    required this.total,
  });

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    return EarningsSummary(
      today: (json['today'] as num?)?.toDouble() ?? 0.0,
      thisWeek: (json['this_week'] as num?)?.toDouble() ?? 0.0,
      thisMonth: (json['this_month'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [today, thisWeek, thisMonth, total];
}

/// Breakdown of a single ride's earnings
class RideEarningsBreakdown extends Equatable {
  final String rideId;
  final double totalAmount;
  final double appFee;
  final double netAmount;
  final PaymentStatus paymentStatus;
  final PaymentMethod paymentMethod;

  const RideEarningsBreakdown({
    required this.rideId,
    required this.totalAmount,
    required this.appFee,
    required this.netAmount,
    required this.paymentStatus,
    required this.paymentMethod,
  });

  factory RideEarningsBreakdown.fromJson(Map<String, dynamic> json) {
    return RideEarningsBreakdown(
      rideId: json['ride_id'] as String? ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      appFee: (json['app_fee'] as num?)?.toDouble() ?? 0.0,
      netAmount: (json['net_amount'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: _parsePaymentStatus(json['payment_status'] as String?),
      paymentMethod: _parsePaymentMethod(json['payment_method'] as String?),
    );
  }

  /// Calculate app fee percentage
  double get appFeePercentage => totalAmount > 0 ? (appFee / totalAmount) * 100 : 0;

  static PaymentStatus _parsePaymentStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.pending;
    }
  }

  static PaymentMethod _parsePaymentMethod(String? method) {
    switch (method?.toLowerCase()) {
      case 'card':
        return PaymentMethod.card;
      case 'stripe':
        return PaymentMethod.stripe;
      default:
        return PaymentMethod.cash;
    }
  }

  @override
  List<Object?> get props => [
    rideId,
    totalAmount,
    appFee,
    netAmount,
    paymentStatus,
    paymentMethod,
  ];
}
