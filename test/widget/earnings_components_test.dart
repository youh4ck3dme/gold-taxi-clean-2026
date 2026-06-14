import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gold_taxi/features/earnings/data/models/earnings_model.dart';
import 'package:gold_taxi/features/earnings/data/models/payout_model.dart';
import 'package:gold_taxi/features/earnings/data/repositories/earnings_repository.dart';
import 'package:intl/intl.dart';

void main() {
  group('Earnings Model Tests', () {
    test('EarningsSummary fromJson parses correctly', () {
      final json = {
        'today': 50.0,
        'this_week': 350.0,
        'this_month': 1500.0,
        'total': 4500.0,
      };

      final summary = EarningsSummary.fromJson(json);

      expect(summary.today, 50.0);
      expect(summary.thisWeek, 350.0);
      expect(summary.thisMonth, 1500.0);
      expect(summary.total, 4500.0);
    });

    test('EarningsModel fromJson parses correctly', () {
      final json = {
        'id': 'earn_1',
        'ride_id': 'ride_1',
        'driver_id': 'driver_1',
        'total_amount': 25.0,
        'app_fee': 3.75,
        'net_amount': 21.25,
        'payment_status': 'completed',
        'payment_method': 'cash',
        'created_at': '2024-01-01T12:00:00Z',
      };

      final earnings = EarningsModel.fromJson(json);

      expect(earnings.id, 'earn_1');
      expect(earnings.rideId, 'ride_1');
      expect(earnings.driverId, 'driver_1');
      expect(earnings.totalAmount, 25.0);
      expect(earnings.appFee, 3.75);
      expect(earnings.netAmount, 21.25);
      expect(earnings.paymentStatus, PaymentStatus.completed);
      expect(earnings.paymentMethod, PaymentMethod.cash);
    });

    test('PayoutModel fromJson parses correctly', () {
      final json = {
        'id': 'payout_1',
        'driver_id': 'driver_1',
        'amount': 100.0,
        'status': 'paid',
        'stripe_payout_id': 'stripe_123',
        'bank_account_last4': '1234',
        'requested_at': '2024-01-01T12:00:00Z',
        'created_at': '2024-01-01T12:00:00Z',
      };

      final payout = PayoutModel.fromJson(json);

      expect(payout.id, 'payout_1');
      expect(payout.driverId, 'driver_1');
      expect(payout.amount, 100.0);
      expect(payout.status, PayoutStatus.paid);
      expect(payout.stripePayoutId, 'stripe_123');
      expect(payout.bankAccountLast4, '1234');
    });

    test('RideEarningsBreakdown appFeePercentage calculation', () {
      const breakdown = RideEarningsBreakdown(
        rideId: 'ride_1',
        totalAmount: 100.0,
        appFee: 15.0,
        netAmount: 85.0,
        paymentStatus: PaymentStatus.completed,
        paymentMethod: PaymentMethod.cash,
      );

      expect(breakdown.appFeePercentage, 15.0);
    });

    test('EarningsModel toJson serializes correctly', () {
      final earnings = EarningsModel(
        id: 'earn_1',
        rideId: 'ride_1',
        driverId: 'driver_1',
        totalAmount: 25.0,
        appFee: 3.75,
        netAmount: 21.25,
        paymentStatus: PaymentStatus.completed,
        paymentMethod: PaymentMethod.cash,
        createdAt: DateTime.parse('2024-01-01T12:00:00Z'),
      );

      final json = earnings.toJson();

      expect(json['id'], 'earn_1');
      expect(json['ride_id'], 'ride_1');
      expect(json['total_amount'], 25.0);
      expect(json['app_fee'], 3.75);
      expect(json['net_amount'], 21.25);
      expect(json['payment_status'], 'completed');
      expect(json['payment_method'], 'cash');
    });

    test('PaymentStatus fromJson handles all cases', () {
      // Test via fromJson which uses the parsing internally
      final completed = EarningsModel.fromJson(const {
        'id': '1', 'ride_id': '1', 'driver_id': '1',
        'total_amount': 1, 'app_fee': 0.15, 'net_amount': 0.85,
        'payment_status': 'completed', 'payment_method': 'cash',
        'created_at': '2024-01-01T00:00:00Z',
      });
      expect(completed.paymentStatus, PaymentStatus.completed);

      final pending = EarningsModel.fromJson(const {
        'id': '1', 'ride_id': '1', 'driver_id': '1',
        'total_amount': 1, 'app_fee': 0.15, 'net_amount': 0.85,
        'payment_status': 'pending', 'payment_method': 'cash',
        'created_at': '2024-01-01T00:00:00Z',
      });
      expect(pending.paymentStatus, PaymentStatus.pending);

      final failed = EarningsModel.fromJson(const {
        'id': '1', 'ride_id': '1', 'driver_id': '1',
        'total_amount': 1, 'app_fee': 0.15, 'net_amount': 0.85,
        'payment_status': 'failed', 'payment_method': 'cash',
        'created_at': '2024-01-01T00:00:00Z',
      });
      expect(failed.paymentStatus, PaymentStatus.failed);

      final refunded = EarningsModel.fromJson(const {
        'id': '1', 'ride_id': '1', 'driver_id': '1',
        'total_amount': 1, 'app_fee': 0.15, 'net_amount': 0.85,
        'payment_status': 'refunded', 'payment_method': 'cash',
        'created_at': '2024-01-01T00:00:00Z',
      });
      expect(refunded.paymentStatus, PaymentStatus.refunded);
    });

    test('PaymentMethod fromJson handles all cases', () {
      final cash = EarningsModel.fromJson(const {
        'id': '1', 'ride_id': '1', 'driver_id': '1',
        'total_amount': 1, 'app_fee': 0.15, 'net_amount': 0.85,
        'payment_status': 'completed', 'payment_method': 'cash',
        'created_at': '2024-01-01T00:00:00Z',
      });
      expect(cash.paymentMethod, PaymentMethod.cash);

      final card = EarningsModel.fromJson(const {
        'id': '1', 'ride_id': '1', 'driver_id': '1',
        'total_amount': 1, 'app_fee': 0.15, 'net_amount': 0.85,
        'payment_status': 'completed', 'payment_method': 'card',
        'created_at': '2024-01-01T00:00:00Z',
      });
      expect(card.paymentMethod, PaymentMethod.card);

      final stripe = EarningsModel.fromJson(const {
        'id': '1', 'ride_id': '1', 'driver_id': '1',
        'total_amount': 1, 'app_fee': 0.15, 'net_amount': 0.85,
        'payment_status': 'completed', 'payment_method': 'stripe',
        'created_at': '2024-01-01T00:00:00Z',
      });
      expect(stripe.paymentMethod, PaymentMethod.stripe);
    });
  });

  group('Payout Model Tests', () {
    test('PayoutStatus fromJson handles all cases', () {
      expect(PayoutModel.fromJson(const {'id': '1', 'driver_id': '1', 'amount': 1, 'status': 'paid', 'requested_at': '2024-01-01T00:00:00Z', 'created_at': '2024-01-01T00:00:00Z'}).status, PayoutStatus.paid);
      expect(PayoutModel.fromJson(const {'id': '1', 'driver_id': '1', 'amount': 1, 'status': 'in_transit', 'requested_at': '2024-01-01T00:00:00Z', 'created_at': '2024-01-01T00:00:00Z'}).status, PayoutStatus.inTransit);
      expect(PayoutModel.fromJson(const {'id': '1', 'driver_id': '1', 'amount': 1, 'status': 'pending', 'requested_at': '2024-01-01T00:00:00Z', 'created_at': '2024-01-01T00:00:00Z'}).status, PayoutStatus.pending);
      expect(PayoutModel.fromJson(const {'id': '1', 'driver_id': '1', 'amount': 1, 'status': 'failed', 'requested_at': '2024-01-01T00:00:00Z', 'created_at': '2024-01-01T00:00:00Z'}).status, PayoutStatus.failed);
      expect(PayoutModel.fromJson(const {'id': '1', 'driver_id': '1', 'amount': 1, 'status': 'cancelled', 'requested_at': '2024-01-01T00:00:00Z', 'created_at': '2024-01-01T00:00:00Z'}).status, PayoutStatus.cancelled);
    });

    test('PayoutModel status helpers work correctly', () {
      final paidPayout = PayoutModel(
        id: 'p1',
        driverId: 'd1',
        amount: 100.0,
        status: PayoutStatus.paid,
        requestedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final pendingPayout = PayoutModel(
        id: 'p2',
        driverId: 'd1',
        amount: 100.0,
        status: PayoutStatus.pending,
        requestedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final inTransitPayout = PayoutModel(
        id: 'p3',
        driverId: 'd1',
        amount: 100.0,
        status: PayoutStatus.inTransit,
        requestedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final failedPayout = PayoutModel(
        id: 'p4',
        driverId: 'd1',
        amount: 100.0,
        status: PayoutStatus.failed,
        requestedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // Paid payouts
      expect(paidPayout.isCompleted, true);
      expect(paidPayout.isInProgress, false);
      expect(paidPayout.hasFailed, false);

      // Pending payouts
      expect(pendingPayout.isCompleted, false);
      expect(pendingPayout.isInProgress, true);
      expect(pendingPayout.hasFailed, false);

      // In transit payouts
      expect(inTransitPayout.isCompleted, false);
      expect(inTransitPayout.isInProgress, true);
      expect(inTransitPayout.hasFailed, false);

      // Failed payouts
      expect(failedPayout.isCompleted, false);
      expect(failedPayout.isInProgress, false);
      expect(failedPayout.hasFailed, true);
    });

    test('PayoutRequestResponse fromJson parses correctly', () {
      final json = {
        'payout_id': 'payout_123',
        'status': 'pending',
        'message': 'Payout requested successfully',
      };

      final response = PayoutRequestResponse.fromJson(json);

      expect(response.payoutId, 'payout_123');
      expect(response.status, 'pending');
      expect(response.message, 'Payout requested successfully');
    });
  });

  group('EarningsRepository Static Methods', () {
    test('calculateAppFee returns 15% of total', () {
      expect(EarningsRepository.calculateAppFee(100.0), 15.0);
      expect(EarningsRepository.calculateAppFee(50.0), 7.5);
      expect(EarningsRepository.calculateAppFee(200.0), 30.0);
      expect(EarningsRepository.calculateAppFee(0.0), 0.0);
    });

    test('calculateNetEarnings returns total minus fee', () {
      expect(EarningsRepository.calculateNetEarnings(100.0), 85.0);
      expect(EarningsRepository.calculateNetEarnings(50.0), 42.5);
      expect(EarningsRepository.calculateNetEarnings(200.0), 170.0);
      expect(EarningsRepository.calculateNetEarnings(0.0), 0.0);
    });

    test('calculateAppFee with custom percentage', () {
      expect(EarningsRepository.calculateAppFee(100.0, appFeePercentage: 20.0), 20.0);
      expect(EarningsRepository.calculateAppFee(100.0, appFeePercentage: 10.0), 10.0);
    });

    test('calculateNetEarnings with custom percentage', () {
      expect(EarningsRepository.calculateNetEarnings(100.0, appFeePercentage: 20.0), 80.0);
      expect(EarningsRepository.calculateNetEarnings(100.0, appFeePercentage: 10.0), 90.0);
    });
  });

  group('Date Formatting Tests', () {
    test('DateFormat produces correct currency format', () {
      final currencyFormat = NumberFormat.currency(
        symbol: '€',
        decimalDigits: 2,
        locale: 'sk_SK',
      );

      // Test that formatting produces valid currency strings
      final formatted25 = currencyFormat.format(25.50);
      final formatted100 = currencyFormat.format(100.0);
      final formatted1234 = currencyFormat.format(1234.56);
      
      // Check that values contain the expected components
      expect(formatted25, contains('25,50'));
      expect(formatted25, contains('€'));
      expect(formatted100, contains('100,00'));
      expect(formatted100, contains('€'));
      expect(formatted1234, contains('234,56'));
      expect(formatted1234, contains('€'));
    });
  });

  group('Equatable Tests', () {
    test('EarningsSummary equality works correctly', () {
      const summary1 = EarningsSummary(
        today: 50.0,
        thisWeek: 350.0,
        thisMonth: 1500.0,
        total: 4500.0,
      );

      const summary2 = EarningsSummary(
        today: 50.0,
        thisWeek: 350.0,
        thisMonth: 1500.0,
        total: 4500.0,
      );

      const summary3 = EarningsSummary(
        today: 100.0,
        thisWeek: 350.0,
        thisMonth: 1500.0,
        total: 4500.0,
      );

      expect(summary1, equals(summary2));
      expect(summary1, isNot(equals(summary3)));
    });

    test('EarningsModel equality works correctly', () {
      final now = DateTime.now();

      final earnings1 = EarningsModel(
        id: 'earn_1',
        rideId: 'ride_1',
        driverId: 'driver_1',
        totalAmount: 25.0,
        appFee: 3.75,
        netAmount: 21.25,
        paymentStatus: PaymentStatus.completed,
        paymentMethod: PaymentMethod.cash,
        createdAt: now,
      );

      final earnings2 = EarningsModel(
        id: 'earn_1',
        rideId: 'ride_1',
        driverId: 'driver_1',
        totalAmount: 25.0,
        appFee: 3.75,
        netAmount: 21.25,
        paymentStatus: PaymentStatus.completed,
        paymentMethod: PaymentMethod.cash,
        createdAt: now,
      );

      expect(earnings1, equals(earnings2));
    });

    test('PayoutModel equality works correctly', () {
      final now = DateTime.now();

      final payout1 = PayoutModel(
        id: 'payout_1',
        driverId: 'driver_1',
        amount: 100.0,
        status: PayoutStatus.paid,
        requestedAt: now,
        createdAt: now,
      );

      final payout2 = PayoutModel(
        id: 'payout_1',
        driverId: 'driver_1',
        amount: 100.0,
        status: PayoutStatus.paid,
        requestedAt: now,
        createdAt: now,
      );

      expect(payout1, equals(payout2));
    });
  });
}
