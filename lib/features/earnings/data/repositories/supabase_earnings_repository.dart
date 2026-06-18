import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/earnings_model.dart';
import '../models/payout_model.dart';
import '../models/bank_account_model.dart';
import 'earnings_repository.dart';

/// Supabase implementation of EarningsRepository
class SupabaseEarningsRepository implements EarningsRepository {
  final SupabaseClient _supabase;
  // ignore: unused_field
  final double _appFeePercentage;

  SupabaseEarningsRepository({
    required this._supabase,
    this._appFeePercentage = 15.0,
  });

  @override
  Future<EarningsSummary> getEarningsSummary(String driverId) async {
    try {
      final data = await _supabase.rpc(
        'get_driver_earnings_summary',
        params: {'p_driver_id': driverId},
      );

      if (data == null) {
        return const EarningsSummary(
          today: 0,
          thisWeek: 0,
          thisMonth: 0,
          total: 0,
        );
      }

      return EarningsSummary.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get earnings summary: $e');
    }
  }

  @override
  Future<RideEarningsBreakdown> getRideEarningsBreakdown(String rideId) async {
    try {
      final data = await _supabase.rpc(
        'get_ride_earnings_breakdown',
        params: {'p_ride_id': rideId},
      );

      if (data == null) {
        throw Exception('No earnings record found');
      }

      final map = data as Map<String, dynamic>;
      if (map.containsKey('error')) {
        throw Exception(map['error'] as String? ?? 'No earnings record found');
      }

      return RideEarningsBreakdown.fromJson(map);
    } catch (e) {
      throw Exception('Failed to get ride earnings breakdown: $e');
    }
  }

  @override
  Future<List<EarningsModel>> getDriverEarnings({
    required String driverId,
    int limit = 20,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      // Build query with filters
      var query = _supabase
          .from('driver_earnings')
          .select()
          .eq('driver_id', driverId);

      // Apply date filters if provided using filter syntax
      if (fromDate != null) {
        query = query.filter('created_at', 'gte', fromDate.toIso8601String());
      }
      if (toDate != null) {
        query = query.filter('created_at', 'lte', toDate.toIso8601String());
      }

      final data = await query
          .order('created_at', ascending: false)
          .limit(limit);

      final list = data as List<dynamic>? ?? [];
      return list
          .map((json) => EarningsModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get driver earnings: $e');
    }
  }

  @override
  Future<List<PayoutModel>> getDriverPayouts({
    required String driverId,
    int limit = 20,
  }) async {
    try {
      final data = await _supabase
          .from('payouts')
          .select()
          .eq('driver_id', driverId)
          .order('requested_at', ascending: false)
          .limit(limit);

      final list = data as List<dynamic>? ?? [];
      return list
          .map((json) => PayoutModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get payouts: $e');
    }
  }

  @override
  Future<PayoutRequestResponse> requestPayout({
    required String driverId,
    required double amount,
    String? stripeAccountId,
    String? bankAccountLast4,
  }) async {
    try {
      final data = await _supabase.rpc(
        'request_driver_payout',
        params: {
          'p_driver_id': driverId,
          'p_amount': amount,
          'p_stripe_account_id': stripeAccountId ?? '',
        },
      );

      final map = data as Map<String, dynamic>? ?? {};
      return PayoutRequestResponse.fromJson(map);
    } catch (e) {
      throw Exception('Failed to request payout: $e');
    }
  }

  @override
  Future<BankAccountModel?> getDriverBankAccount(String driverId) async {
    try {
      final response = await _supabase
          .from('driver_bank_accounts')
          .select()
          .eq('driver_id', driverId)
          .maybeSingle();

      if (response == null) return null;
      return BankAccountModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get driver bank account: $e');
    }
  }

  @override
  Future<void> saveDriverBankAccount(BankAccountModel bankAccount) async {
    try {
      await _supabase.from('driver_bank_accounts').upsert(bankAccount.toJson());
    } catch (e) {
      throw Exception('Failed to save driver bank account: $e');
    }
  }
}
