import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../models/promo_code_model.dart';
import 'promo_repository.dart';

/// Supabase implementation of PromoRepository
class SupabasePromoRepository implements PromoRepository {
  final SupabaseClient _supabase;

  SupabasePromoRepository(this._supabase);

  @override
  Future<PromoCodeModel> validatePromoCode({
    required String code,
    required String userId,
    required double rideAmount,
  }) async {
    try {
      final response = await _supabase.rpc(
        'validate_promo_code',
        params: {
          'p_user_id': userId,
          'p_code': code.trim().toUpperCase(),
          'p_ride_amount': rideAmount,
        },
      );

      final list = response as List<dynamic>? ?? [];
      if (list.isEmpty) {
        return PromoCodeModel(
          code: code,
          discountPercentage: 0.0,
          discountAmount: 0.0,
          calculatedDiscount: 0.0,
          isValid: false,
          errorMessage: 'Nepodarilo sa overiť kód',
        );
      }

      final data = list[0] as Map<String, dynamic>;
      return PromoCodeModel.fromJson(data);
    } catch (e) {
      return PromoCodeModel(
        code: code,
        discountPercentage: 0.0,
        discountAmount: 0.0,
        calculatedDiscount: 0.0,
        isValid: false,
        errorMessage: 'Chyba komunikácie: $e',
      );
    }
  }

  @override
  Future<void> usePromoCode({
    required String code,
    required String userId,
    required String rideId,
  }) async {
    try {
      final cleanCode = code.trim().toUpperCase();

      // 1. Try to find a standard promo code
      final promoResponse = await _supabase
          .from('promo_codes')
          .select('id')
          .eq('code', cleanCode)
          .maybeSingle();

      if (promoResponse != null) {
        final promoId = promoResponse['id'] as String;
        await _supabase.from('user_promos').insert({
          'user_id': userId,
          'promo_code_id': promoId,
          'ride_id': rideId,
        });
      } else {
        // 2. Try to find if it is a referral code
        final referrerResponse = await _supabase
            .from('profiles')
            .select('id')
            .eq('referral_code', cleanCode)
            .maybeSingle();

        if (referrerResponse != null) {
          final referrerId = referrerResponse['id'] as String;
          await _supabase
              .from('profiles')
              .update({'referred_by': referrerId})
              .eq('id', userId);
        }
      }
    } catch (e) {
      // Log/ignore errors
      // ignore: avoid_print
      print('Error applying promo code: $e');
    }
  }
}
