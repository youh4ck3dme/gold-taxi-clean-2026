import 'package:flutter_test/flutter_test.dart';
import 'package:gold_taxi/features/earnings/data/repositories/mock_earnings_repository.dart';
import 'package:gold_taxi/features/earnings/data/models/earnings_model.dart';
import 'package:gold_taxi/features/earnings/data/models/payout_model.dart';

void main() {
  group('MockEarningsRepository Tests', () {
    late MockEarningsRepository repository;

    setUp(() {
      repository = MockEarningsRepository(appFeePercentage: 15.0);
    });

    test('getEarningsSummary returns mocked earnings summary', () async {
      final summary = await repository.getEarningsSummary('driver_test');
      expect(summary.today, 45.50);
      expect(summary.thisWeek, 285.75);
      expect(summary.thisMonth, 1245.30);
      expect(summary.total, 4520.80);
    });

    test('getRideEarningsBreakdown returns breakdown with correct calculations', () async {
      final breakdown = await repository.getRideEarningsBreakdown('ride_1');
      expect(breakdown.rideId, 'ride_1');
      expect(breakdown.totalAmount, greaterThanOrEqualTo(25.0));
      expect(breakdown.appFee, closeTo(breakdown.totalAmount * 0.15, 0.01));
      expect(breakdown.netAmount, closeTo(breakdown.totalAmount * 0.85, 0.01));
      expect(breakdown.paymentStatus, PaymentStatus.completed);
    });

    test('getDriverEarnings returns correct count and data', () async {
      final earningsList = await repository.getDriverEarnings(driverId: 'driver_test', limit: 5);
      expect(earningsList.length, 5);
      for (final earn in earningsList) {
        expect(earn.driverId, 'driver_test');
        expect(earn.appFee, closeTo(earn.totalAmount * 0.15, 0.01));
        expect(earn.netAmount, closeTo(earn.totalAmount * 0.85, 0.01));
        expect(earn.paymentStatus, PaymentStatus.completed);
      }
    });

    test('getDriverPayouts returns list of payouts', () async {
      final payoutsList = await repository.getDriverPayouts(driverId: 'driver_test', limit: 3);
      expect(payoutsList.length, 3);
      for (final payout in payoutsList) {
        expect(payout.driverId, 'driver_test');
        expect(payout.bankAccountLast4, '1234');
        expect(payout.amount, greaterThanOrEqualTo(200.0));
      }
    });

    test('requestPayout returns successful pending response', () async {
      final response = await repository.requestPayout(
        driverId: 'driver_test',
        amount: 150.0,
        bankAccountLast4: '1234',
      );
      expect(response.payoutId, startsWith('payout_driver_test_'));
      expect(response.status, 'pending');
      expect(response.message, contains('created successfully'));
    });
  });
}
