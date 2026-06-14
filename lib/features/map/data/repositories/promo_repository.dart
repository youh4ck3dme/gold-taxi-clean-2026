import '../../../../models/promo_code_model.dart';

/// Abstract repository for validating and applying promo/referral codes
abstract class PromoRepository {
  /// Validate a promo code or referral code against a ride amount
  Future<PromoCodeModel> validatePromoCode({
    required String code,
    required String userId,
    required double rideAmount,
  });

  /// Record usage of a promo code when booking a ride
  Future<void> usePromoCode({
    required String code,
    required String userId,
    required String rideId,
  });
}
