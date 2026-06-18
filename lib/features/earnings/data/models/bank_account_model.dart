import 'package:equatable/equatable.dart';

class BankAccountModel extends Equatable {
  final String id;
  final String driverId;
  final String stripeAccountId;
  final String? bankAccountId;
  final String? bankAccountLast4;
  final String? bankName;
  final String? accountHolderName;
  final String accountHolderType; // 'individual' or 'company'
  final String currency;
  final String status; // 'pending', 'verified', 'failed', 'revoked', 'disabled'
  final bool payoutEnabled;

  const BankAccountModel({
    required this.id,
    required this.driverId,
    required this.stripeAccountId,
    this.bankAccountId,
    this.bankAccountLast4,
    this.bankName,
    this.accountHolderName,
    required this.accountHolderType,
    required this.currency,
    required this.status,
    required this.payoutEnabled,
  });

  factory BankAccountModel.fromJson(Map<String, dynamic> json) {
    return BankAccountModel(
      id: json['id'] as String? ?? '',
      driverId: json['driver_id'] as String? ?? '',
      stripeAccountId: json['stripe_account_id'] as String? ?? '',
      bankAccountId: json['bank_account_id'] as String?,
      bankAccountLast4: json['bank_account_last4'] as String?,
      bankName: json['bank_name'] as String?,
      accountHolderName: json['account_holder_name'] as String?,
      accountHolderType: json['account_holder_type'] as String? ?? 'individual',
      currency: json['currency'] as String? ?? 'eur',
      status: json['status'] as String? ?? 'pending',
      payoutEnabled: json['payout_enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'driver_id': driverId,
      'stripe_account_id': stripeAccountId,
      'bank_account_id': bankAccountId,
      'bank_account_last4': bankAccountLast4,
      'bank_name': bankName,
      'account_holder_name': accountHolderName,
      'account_holder_type': accountHolderType,
      'currency': currency,
      'status': status,
      'payout_enabled': payoutEnabled,
    };
  }

  BankAccountModel copyWith({
    String? id,
    String? driverId,
    String? stripeAccountId,
    String? bankAccountId,
    String? bankAccountLast4,
    String? bankName,
    String? accountHolderName,
    String? accountHolderType,
    String? currency,
    String? status,
    bool? payoutEnabled,
  }) {
    return BankAccountModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      stripeAccountId: stripeAccountId ?? this.stripeAccountId,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      bankAccountLast4: bankAccountLast4 ?? this.bankAccountLast4,
      bankName: bankName ?? this.bankName,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      accountHolderType: accountHolderType ?? this.accountHolderType,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      payoutEnabled: payoutEnabled ?? this.payoutEnabled,
    );
  }

  @override
  List<Object?> get props => [
    id,
    driverId,
    stripeAccountId,
    bankAccountId,
    bankAccountLast4,
    bankName,
    accountHolderName,
    accountHolderType,
    currency,
    status,
    payoutEnabled,
  ];
}
