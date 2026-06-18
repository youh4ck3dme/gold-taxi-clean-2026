import 'package:equatable/equatable.dart';

/// Status of a payout request
enum PayoutStatus { pending, inTransit, paid, failed, cancelled }

/// Model for driver payout requests
class PayoutModel extends Equatable {
  final String id;
  final String driverId;
  final double amount;
  final String? stripePayoutId;
  final String? bankAccountLast4;
  final PayoutStatus status;
  final DateTime requestedAt;
  final DateTime? completedAt;
  final DateTime createdAt;

  const PayoutModel({
    required this.id,
    required this.driverId,
    required this.amount,
    this.stripePayoutId,
    this.bankAccountLast4,
    required this.status,
    required this.requestedAt,
    this.completedAt,
    required this.createdAt,
  });

  /// Create from JSON (Supabase)
  factory PayoutModel.fromJson(Map<String, dynamic> json) {
    return PayoutModel(
      id: json['id'] as String? ?? '',
      driverId: json['driver_id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      stripePayoutId: json['stripe_payout_id'] as String?,
      bankAccountLast4: json['bank_account_last4'] as String?,
      status: _parsePayoutStatus(json['status'] as String?),
      requestedAt: json['requested_at'] != null
          ? DateTime.parse(json['requested_at'] as String)
          : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'amount': amount,
      'stripe_payout_id': stripePayoutId,
      'bank_account_last4': bankAccountLast4,
      'status': status.name,
      'requested_at': requestedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Helper to parse PayoutStatus
  static PayoutStatus _parsePayoutStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'in_transit':
        return PayoutStatus.inTransit;
      case 'paid':
        return PayoutStatus.paid;
      case 'failed':
        return PayoutStatus.failed;
      case 'cancelled':
        return PayoutStatus.cancelled;
      default:
        return PayoutStatus.pending;
    }
  }

  /// Check if payout is completed
  bool get isCompleted => status == PayoutStatus.paid;

  /// Check if payout is in progress
  bool get isInProgress =>
      status == PayoutStatus.pending || status == PayoutStatus.inTransit;

  /// Check if payout failed
  bool get hasFailed =>
      status == PayoutStatus.failed || status == PayoutStatus.cancelled;

  @override
  List<Object?> get props => [
    id,
    driverId,
    amount,
    stripePayoutId,
    bankAccountLast4,
    status,
    requestedAt,
    completedAt,
    createdAt,
  ];
}

/// Response from payout request
class PayoutRequestResponse extends Equatable {
  final String? payoutId;
  final String status;
  final String message;

  const PayoutRequestResponse({
    this.payoutId,
    required this.status,
    required this.message,
  });

  factory PayoutRequestResponse.fromJson(Map<String, dynamic> json) {
    return PayoutRequestResponse(
      payoutId: json['payout_id'] as String?,
      status: json['status'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [payoutId, status, message];
}
