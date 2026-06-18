import 'dart:async';
import '../../../../models/promo_code_model.dart';
import 'promo_repository.dart';

/// Mock implementation of PromoRepository for offline testing and demoing
class MockPromoRepository implements PromoRepository {
  @override
  Future<PromoCodeModel> validatePromoCode({
    required String code,
    required String userId,
    required double rideAmount,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final cleanCode = code.trim().toUpperCase();

    if (cleanCode == 'ZNAK10') {
      final discount = (rideAmount * 0.1);
      return PromoCodeModel(
        id: 'promo_znak10',
        code: cleanCode,
        discountPercentage: 10.0,
        discountAmount: 0.0,
        calculatedDiscount: double.parse(discount.toStringAsFixed(2)),
        isValid: true,
      );
    } else if (cleanCode == 'TAXI5') {
      final discount = rideAmount > 5.0 ? 5.0 : rideAmount;
      return PromoCodeModel(
        id: 'promo_taxi5',
        code: cleanCode,
        discountPercentage: 0.0,
        discountAmount: 5.0,
        calculatedDiscount: double.parse(discount.toStringAsFixed(2)),
        isValid: true,
      );
    } else if (cleanCode.length >= 6 &&
        RegExp(r'^[A-Z]{4}\d{2}$').hasMatch(cleanCode)) {
      // Mock referral code validation
      if (cleanCode == 'MYRE12' || cleanCode == 'SELF99') {
        return PromoCodeModel(
          code: cleanCode,
          discountPercentage: 0.0,
          discountAmount: 0.0,
          calculatedDiscount: 0.0,
          isValid: false,
          errorMessage: 'Nemôžete použiť vlastný referenčný kód',
        );
      }

      final discount = rideAmount > 5.0 ? 5.0 : rideAmount;
      return PromoCodeModel(
        id: 'referral_$cleanCode',
        code: cleanCode,
        discountPercentage: 0.0,
        discountAmount: 5.0,
        calculatedDiscount: double.parse(discount.toStringAsFixed(2)),
        isValid: true,
      );
    }

    return PromoCodeModel(
      code: code,
      discountPercentage: 0.0,
      discountAmount: 0.0,
      calculatedDiscount: 0.0,
      isValid: false,
      errorMessage: 'Neplatný kód',
    );
  }

  @override
  Future<void> usePromoCode({
    required String code,
    required String userId,
    required String rideId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
