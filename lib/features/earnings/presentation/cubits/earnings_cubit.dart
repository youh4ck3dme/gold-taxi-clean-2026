import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/earnings_repository.dart';
import '../../data/models/bank_account_model.dart';
import 'earnings_state.dart';

/// Cubit for managing driver earnings state
class EarningsCubit extends Cubit<EarningsState> {
  final EarningsRepository _earningsRepository;
  final String driverId;

  EarningsCubit({required this._earningsRepository, required this.driverId})
    : super(EarningsInitial());

  /// Load earnings summary and recent earnings
  Future<void> loadEarningsSummary() async {
    if (driverId.isEmpty) {
      emit(const EarningsError('Neautorizovaný prístup. ID vodiča chýba.'));
      return;
    }
    try {
      emit(EarningsLoading());

      final summary = await _earningsRepository.getEarningsSummary(driverId);
      final recentEarnings = await _earningsRepository.getDriverEarnings(
        driverId: driverId,
        limit: 10,
      );

      emit(
        EarningsSummaryLoaded(summary: summary, recentEarnings: recentEarnings),
      );
    } catch (e) {
      emit(EarningsError(e.toString()));
    }
  }

  /// Load ride earnings breakdown
  Future<void> loadRideEarningsBreakdown(String rideId) async {
    try {
      emit(EarningsLoading());

      final breakdown = await _earningsRepository.getRideEarningsBreakdown(
        rideId,
      );

      emit(RideEarningsBreakdownLoaded(breakdown));
    } catch (e) {
      emit(EarningsError(e.toString()));
    }
  }

  /// Load payouts history
  Future<void> loadPayouts() async {
    if (driverId.isEmpty) {
      emit(const EarningsError('Neautorizovaný prístup. ID vodiča chýba.'));
      return;
    }
    try {
      emit(EarningsLoading());

      final payouts = await _earningsRepository.getDriverPayouts(
        driverId: driverId,
        limit: 20,
      );

      emit(PayoutsLoaded(payouts));
    } catch (e) {
      emit(EarningsError(e.toString()));
    }
  }

  /// Load all data (summary, earnings, payouts) with optional date filtering
  Future<void> loadAllData({DateTime? fromDate, DateTime? toDate}) async {
    if (driverId.isEmpty) {
      emit(const EarningsError('Neautorizovaný prístup. ID vodiča chýba.'));
      return;
    }
    try {
      emit(EarningsLoading());

      final summary = await _earningsRepository.getEarningsSummary(driverId);
      final recentEarnings = await _earningsRepository.getDriverEarnings(
        driverId: driverId,
        limit: 20,
        fromDate: fromDate,
        toDate: toDate,
      );
      final payouts = await _earningsRepository.getDriverPayouts(
        driverId: driverId,
        limit: 20,
      );
      final bankAccount = await _earningsRepository.getDriverBankAccount(
        driverId,
      );

      emit(
        EarningsDataLoaded(
          summary: summary,
          recentEarnings: recentEarnings,
          payouts: payouts,
          bankAccount: bankAccount,
        ),
      );
    } catch (e) {
      emit(EarningsError(e.toString()));
    }
  }

  /// Request a payout
  Future<void> requestPayout({
    required double amount,
    String? stripeAccountId,
    String? bankAccountLast4,
  }) async {
    if (driverId.isEmpty) {
      emit(const EarningsError('Neautorizovaný prístup. ID vodiča chýba.'));
      return;
    }
    try {
      emit(EarningsLoading());

      final response = await _earningsRepository.requestPayout(
        driverId: driverId,
        amount: amount,
        stripeAccountId: stripeAccountId,
        bankAccountLast4: bankAccountLast4,
      );

      emit(PayoutRequested(response));

      // Reload data after payout request
      await loadAllData();
    } catch (e) {
      emit(EarningsError(e.toString()));
    }
  }

  /// Save or update driver bank account
  Future<void> saveDriverBankAccount(BankAccountModel bankAccount) async {
    if (driverId.isEmpty) {
      emit(const EarningsError('Neautorizovaný prístup. ID vodiča chýba.'));
      return;
    }
    try {
      emit(EarningsLoading());
      await _earningsRepository.saveDriverBankAccount(bankAccount);
      await loadAllData();
    } catch (e) {
      emit(EarningsError(e.toString()));
    }
  }

  /// Calculate app fee from total amount
  double calculateAppFee(double totalAmount) {
    return EarningsRepository.calculateAppFee(totalAmount);
  }

  /// Calculate net earnings from total amount
  double calculateNetEarnings(double totalAmount) {
    return EarningsRepository.calculateNetEarnings(totalAmount);
  }

  /// Get app fee percentage (default 15%)
  static const double appFeePercentage = 15.0;
}
