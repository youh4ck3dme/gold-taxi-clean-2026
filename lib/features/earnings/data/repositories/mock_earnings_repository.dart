import 'dart:math';
import '../models/earnings_model.dart';
import '../models/payout_model.dart';
import '../models/bank_account_model.dart';
import 'earnings_repository.dart';

/// Mock implementation of EarningsRepository for testing
class MockEarningsRepository implements EarningsRepository {
  final double _appFeePercentage;
  final Random _random = Random();

  MockEarningsRepository({this._appFeePercentage = 15.0});

  @override
  Future<EarningsSummary> getEarningsSummary(String driverId) async {
    // Simulate some earnings data
    await Future.delayed(const Duration(milliseconds: 100));

    return const EarningsSummary(
      today: 45.50,
      thisWeek: 285.75,
      thisMonth: 1245.30,
      total: 4520.80,
    );
  }

  @override
  Future<RideEarningsBreakdown> getRideEarningsBreakdown(String rideId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final totalAmount = 25.0 + _random.nextDouble() * 50;
    final appFee = EarningsRepository.calculateAppFee(
      totalAmount,
      appFeePercentage: _appFeePercentage,
    );
    final netAmount = EarningsRepository.calculateNetEarnings(
      totalAmount,
      appFeePercentage: _appFeePercentage,
    );

    return RideEarningsBreakdown(
      rideId: rideId,
      totalAmount: totalAmount,
      appFee: appFee,
      netAmount: netAmount,
      paymentStatus: PaymentStatus.completed,
      paymentMethod: [
        PaymentMethod.cash,
        PaymentMethod.card,
        PaymentMethod.stripe,
      ][_random.nextInt(3)],
    );
  }

  @override
  Future<List<EarningsModel>> getDriverEarnings({
    required String driverId,
    int limit = 20,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final now = DateTime.now();
    final List<EarningsModel> earnings = [];

    for (int i = 0; i < min(limit, 15); i++) {
      final daysAgo = i * 2;
      final date = now.subtract(Duration(days: daysAgo));
      final totalAmount = 15.0 + _random.nextDouble() * 40;
      final appFee = EarningsRepository.calculateAppFee(
        totalAmount,
        appFeePercentage: _appFeePercentage,
      );
      final netAmount = EarningsRepository.calculateNetEarnings(
        totalAmount,
        appFeePercentage: _appFeePercentage,
      );

      earnings.add(
        EarningsModel(
          id: 'earning_${driverId}_$i',
          rideId: 'ride_$i',
          driverId: driverId,
          totalAmount: totalAmount,
          appFee: appFee,
          netAmount: netAmount,
          paymentStatus: PaymentStatus.completed,
          paymentMethod: [
            PaymentMethod.cash,
            PaymentMethod.card,
          ][_random.nextInt(2)],
          createdAt: date,
        ),
      );
    }

    return earnings;
  }

  @override
  Future<List<PayoutModel>> getDriverPayouts({
    required String driverId,
    int limit = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final now = DateTime.now();
    final List<PayoutModel> payouts = [];

    for (int i = 0; i < min(limit, 5); i++) {
      final weeksAgo = i * 2;
      final date = now.subtract(Duration(days: weeksAgo * 7));

      payouts.add(
        PayoutModel(
          id: 'payout_${driverId}_$i',
          driverId: driverId,
          amount: 200.0 + _random.nextDouble() * 100,
          stripePayoutId: i.isEven ? 'stripe_payout_$i' : null,
          bankAccountLast4: '1234',
          status: [
            PayoutStatus.paid,
            PayoutStatus.inTransit,
            PayoutStatus.pending,
          ][_random.nextInt(3)],
          requestedAt: date,
          completedAt: i.isEven ? date.add(const Duration(days: 2)) : null,
          createdAt: date,
        ),
      );
    }

    return payouts;
  }

  @override
  Future<PayoutRequestResponse> requestPayout({
    required String driverId,
    required double amount,
    String? stripeAccountId,
    String? bankAccountLast4,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    return PayoutRequestResponse(
      payoutId: 'payout_${driverId}_${DateTime.now().millisecondsSinceEpoch}',
      status: 'pending',
      message: 'Payout request created successfully (mock)',
    );
  }

  BankAccountModel? _mockBankAccount;

  @override
  Future<BankAccountModel?> getDriverBankAccount(String driverId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    return _mockBankAccount ??= BankAccountModel(
      id: 'mock_bank_1',
      driverId: driverId,
      stripeAccountId: 'acct_mock_stripe123',
      bankAccountId: 'ba_mock_bank123',
      bankAccountLast4: '8899',
      bankName: 'Tatra Banka, a.s.',
      accountHolderName: 'Ján Kováč',
      accountHolderType: 'individual',
      currency: 'eur',
      status: 'verified',
      payoutEnabled: true,
    );
  }

  @override
  Future<void> saveDriverBankAccount(BankAccountModel bankAccount) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _mockBankAccount = bankAccount.copyWith(id: 'mock_bank_new');
  }
}
