import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gold_taxi/features/earnings/presentation/cubits/earnings_cubit.dart';
import 'package:gold_taxi/features/earnings/presentation/cubits/earnings_state.dart';
import 'package:gold_taxi/features/earnings/data/repositories/earnings_repository.dart';
import 'package:gold_taxi/features/earnings/data/models/earnings_model.dart';
import 'package:gold_taxi/features/earnings/data/models/payout_model.dart';
import 'package:gold_taxi/features/earnings/data/models/bank_account_model.dart';

class MockEarningsRepository extends Mock implements EarningsRepository {}

void main() {
  late EarningsCubit earningsCubit;
  late MockEarningsRepository mockEarningsRepository;
  const String testDriverId = 'driver_test';

  setUp(() {
    mockEarningsRepository = MockEarningsRepository();
    earningsCubit = EarningsCubit(
      earningsRepository: mockEarningsRepository,
      driverId: testDriverId,
    );
  });

  tearDown(() async {
    await earningsCubit.close();
  });

  group('EarningsCubit Tests', () {
    const testSummary = EarningsSummary(
      today: 50.0,
      thisWeek: 350.0,
      thisMonth: 1500.0,
      total: 4500.0,
    );

    final testEarnings = [
      EarningsModel(
        id: 'earn_1',
        driverId: testDriverId,
        rideId: 'ride_1',
        totalAmount: 20.0,
        appFee: 3.0,
        netAmount: 17.0,
        paymentStatus: PaymentStatus.completed,
        paymentMethod: PaymentMethod.cash,
        createdAt: DateTime.now(),
      ),
    ];

    final testPayouts = [
      PayoutModel(
        id: 'payout_1',
        driverId: testDriverId,
        amount: 100.0,
        status: PayoutStatus.paid,
        requestedAt: DateTime.now(),
        createdAt: DateTime.now(),
        bankAccountLast4: '1234',
      ),
    ];

    test('Initial state is EarningsInitial', () {
      expect(earningsCubit.state, isA<EarningsInitial>());
    });

    test('loadEarningsSummary emits [EarningsLoading, EarningsSummaryLoaded] on success', () async {
      when(() => mockEarningsRepository.getEarningsSummary(testDriverId))
          .thenAnswer((_) async => testSummary);
      when(() => mockEarningsRepository.getDriverEarnings(
            driverId: testDriverId,
            limit: 10,
          )).thenAnswer((_) async => testEarnings);

      expectLater(
        earningsCubit.stream,
        emitsInOrder([
          isA<EarningsLoading>(),
          predicate<EarningsState>((state) {
            if (state is! EarningsSummaryLoaded) return false;
            expect(state.summary, testSummary);
            expect(state.recentEarnings, testEarnings);
            return true;
          }),
        ]),
      );

      await earningsCubit.loadEarningsSummary();
    });

    test('loadEarningsSummary emits [EarningsLoading, EarningsError] on failure', () async {
      when(() => mockEarningsRepository.getEarningsSummary(testDriverId))
          .thenThrow(Exception('API Error'));

      expectLater(
        earningsCubit.stream,
        emitsInOrder([
          isA<EarningsLoading>(),
          isA<EarningsError>(),
        ]),
      );

      await earningsCubit.loadEarningsSummary();
    });

    test('loadRideEarningsBreakdown emits [EarningsLoading, RideEarningsBreakdownLoaded] on success', () async {
      const breakdown = RideEarningsBreakdown(
        rideId: 'ride_1',
        totalAmount: 25.0,
        appFee: 3.75,
        netAmount: 21.25,
        paymentStatus: PaymentStatus.completed,
        paymentMethod: PaymentMethod.cash,
      );

      when(() => mockEarningsRepository.getRideEarningsBreakdown('ride_1'))
          .thenAnswer((_) async => breakdown);

      expectLater(
        earningsCubit.stream,
        emitsInOrder([
          isA<EarningsLoading>(),
          predicate<EarningsState>((state) {
            if (state is! RideEarningsBreakdownLoaded) return false;
            expect(state.breakdown, breakdown);
            return true;
          }),
        ]),
      );

      await earningsCubit.loadRideEarningsBreakdown('ride_1');
    });

    test('loadPayouts emits [EarningsLoading, PayoutsLoaded] on success', () async {
      when(() => mockEarningsRepository.getDriverPayouts(
            driverId: testDriverId,
            limit: 20,
          )).thenAnswer((_) async => testPayouts);

      expectLater(
        earningsCubit.stream,
        emitsInOrder([
          isA<EarningsLoading>(),
          predicate<EarningsState>((state) {
            if (state is! PayoutsLoaded) return false;
            expect(state.payouts, testPayouts);
            return true;
          }),
        ]),
      );

      await earningsCubit.loadPayouts();
    });

    test('loadAllData emits [EarningsLoading, EarningsDataLoaded] on success', () async {
      when(() => mockEarningsRepository.getEarningsSummary(testDriverId))
          .thenAnswer((_) async => testSummary);
      when(() => mockEarningsRepository.getDriverEarnings(
            driverId: testDriverId,
            limit: 20,
            fromDate: any(named: 'fromDate'),
            toDate: any(named: 'toDate'),
          )).thenAnswer((_) async => testEarnings);
      when(() => mockEarningsRepository.getDriverPayouts(
            driverId: testDriverId,
            limit: 20,
          )).thenAnswer((_) async => testPayouts);
      when(() => mockEarningsRepository.getDriverBankAccount(testDriverId))
          .thenAnswer((_) async => null);

      expectLater(
        earningsCubit.stream,
        emitsInOrder([
          isA<EarningsLoading>(),
          predicate<EarningsState>((state) {
            if (state is! EarningsDataLoaded) return false;
            expect(state.summary, testSummary);
            expect(state.recentEarnings, testEarnings);
            expect(state.payouts, testPayouts);
            return true;
          }),
        ]),
      );

      await earningsCubit.loadAllData();
    });

    test('requestPayout calls repository, emits [EarningsLoading, PayoutRequested, EarningsLoading, EarningsDataLoaded]', () async {
      const response = PayoutRequestResponse(
        payoutId: 'payout_123',
        status: 'pending',
        message: 'Payout requested successfully',
      );

      when(() => mockEarningsRepository.requestPayout(
            driverId: testDriverId,
            amount: 50.0,
            stripeAccountId: null,
            bankAccountLast4: '1234',
          )).thenAnswer((_) async => response);

      // Setup for loadAllData inside requestPayout
      when(() => mockEarningsRepository.getEarningsSummary(testDriverId))
          .thenAnswer((_) async => testSummary);
      when(() => mockEarningsRepository.getDriverEarnings(
            driverId: testDriverId,
            limit: 20,
            fromDate: any(named: 'fromDate'),
            toDate: any(named: 'toDate'),
          )).thenAnswer((_) async => testEarnings);
      when(() => mockEarningsRepository.getDriverPayouts(
            driverId: testDriverId,
            limit: 20,
          )).thenAnswer((_) async => testPayouts);
      when(() => mockEarningsRepository.getDriverBankAccount(testDriverId))
          .thenAnswer((_) async => null);

      expectLater(
        earningsCubit.stream,
        emitsInOrder([
          isA<EarningsLoading>(),
          predicate<EarningsState>((state) {
            if (state is! PayoutRequested) return false;
            expect(state.response.status, 'pending');
            return true;
          }),
          isA<EarningsLoading>(),
          isA<EarningsDataLoaded>(),
        ]),
      );

      await earningsCubit.requestPayout(
        amount: 50.0,
        bankAccountLast4: '1234',
      );

      verify(() => mockEarningsRepository.requestPayout(
            driverId: testDriverId,
            amount: 50.0,
            stripeAccountId: null,
            bankAccountLast4: '1234',
          )).called(1);
    });

    test('calculateAppFee and calculateNetEarnings helper methods work correctly', () {
      expect(earningsCubit.calculateAppFee(100.0), 15.0);
      expect(earningsCubit.calculateNetEarnings(100.0), 85.0);
    });
  });
}
