import '../models/earnings_model.dart';
import '../models/payout_model.dart';
import '../models/bank_account_model.dart';

/// Abstract repository for driver earnings and payouts
abstract class EarningsRepository {
  /// Get earnings summary for a driver (today, this week, this month, total)
  Future<EarningsSummary> getEarningsSummary(String driverId);

  /// Get earnings for a specific ride
  Future<RideEarningsBreakdown> getRideEarningsBreakdown(String rideId);

  /// Get list of recent earnings for a driver
  Future<List<EarningsModel>> getDriverEarnings({
    required String driverId,
    int limit = 20,
    DateTime? fromDate,
    DateTime? toDate,
  });

  /// Get list of payouts for a driver
  Future<List<PayoutModel>> getDriverPayouts({
    required String driverId,
    int limit = 20,
  });

  /// Request a payout to driver's bank account
  Future<PayoutRequestResponse> requestPayout({
    required String driverId,
    required double amount,
    String? stripeAccountId,
    String? bankAccountLast4,
  });

  /// Get driver bank account
  Future<BankAccountModel?> getDriverBankAccount(String driverId);

  /// Save or update driver bank account
  Future<void> saveDriverBankAccount(BankAccountModel bankAccount);

  /// Calculate net earnings from total amount (apply app fee)
  static double calculateNetEarnings(
    double totalAmount, {
    double appFeePercentage = 15.0,
  }) {
    final feeAmount = totalAmount * (appFeePercentage / 100);
    return totalAmount - feeAmount;
  }

  /// Calculate app fee from total amount
  static double calculateAppFee(
    double totalAmount, {
    double appFeePercentage = 15.0,
  }) {
    return totalAmount * (appFeePercentage / 100);
  }
}
