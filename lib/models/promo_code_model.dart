import 'package:equatable/equatable.dart';

/// Data model representing a promo code, its discount configuration, and validation status
class PromoCodeModel extends Equatable {
  final String? id;
  final String code;
  final double discountPercentage;
  final double discountAmount;
  final double calculatedDiscount;
  final bool isValid;
  final String? errorMessage;

  const PromoCodeModel({
    this.id,
    required this.code,
    required this.discountPercentage,
    required this.discountAmount,
    required this.calculatedDiscount,
    required this.isValid,
    this.errorMessage,
  });

  factory PromoCodeModel.fromJson(Map<String, dynamic> json) {
    return PromoCodeModel(
      id: json['id'] as String?,
      code: json['code'] as String? ?? '',
      discountPercentage: (json['discount_percentage'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      calculatedDiscount: (json['calculated_discount'] as num?)?.toDouble() ?? 0.0,
      isValid: json['is_valid'] as bool? ?? false,
      errorMessage: json['error_message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'code': code,
      'discount_percentage': discountPercentage,
      'discount_amount': discountAmount,
      'calculated_discount': calculatedDiscount,
      'is_valid': isValid,
      if (errorMessage != null) 'error_message': errorMessage,
    };
  }

  PromoCodeModel copyWith({
    String? id,
    String? code,
    double? discountPercentage,
    double? discountAmount,
    double? calculatedDiscount,
    bool? isValid,
    String? errorMessage,
  }) {
    return PromoCodeModel(
      id: id ?? this.id,
      code: code ?? this.code,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountAmount: discountAmount ?? this.discountAmount,
      calculatedDiscount: calculatedDiscount ?? this.calculatedDiscount,
      isValid: isValid ?? this.isValid,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        id,
        code,
        discountPercentage,
        discountAmount,
        calculatedDiscount,
        isValid,
        errorMessage,
      ];
}
