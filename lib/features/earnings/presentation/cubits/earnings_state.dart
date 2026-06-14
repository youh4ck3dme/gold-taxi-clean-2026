import 'package:equatable/equatable.dart';
import '../../data/models/earnings_model.dart';
import '../../data/models/payout_model.dart';
import '../../data/models/bank_account_model.dart';

/// Base state for earnings
abstract class EarningsState extends Equatable {
  const EarningsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class EarningsInitial extends EarningsState {}

/// Loading state
class EarningsLoading extends EarningsState {}

/// Error state
class EarningsError extends EarningsState {
  final String message;

  const EarningsError(this.message);

  @override
  List<Object?> get props => [message];
}

/// State with earnings summary loaded
class EarningsSummaryLoaded extends EarningsState {
  final EarningsSummary summary;
  final List<EarningsModel> recentEarnings;

  const EarningsSummaryLoaded({
    required this.summary,
    required this.recentEarnings,
  });

  @override
  List<Object?> get props => [summary, recentEarnings];
}

/// State with ride earnings breakdown
class RideEarningsBreakdownLoaded extends EarningsState {
  final RideEarningsBreakdown breakdown;

  const RideEarningsBreakdownLoaded(this.breakdown);

  @override
  List<Object?> get props => [breakdown];
}

/// State with payouts loaded
class PayoutsLoaded extends EarningsState {
  final List<PayoutModel> payouts;

  const PayoutsLoaded(this.payouts);

  @override
  List<Object?> get props => [payouts];
}

/// State after successful payout request
class PayoutRequested extends EarningsState {
  final PayoutRequestResponse response;

  const PayoutRequested(this.response);

  @override
  List<Object?> get props => [response];
}

/// Combined state with all data
class EarningsDataLoaded extends EarningsState {
  final EarningsSummary summary;
  final List<EarningsModel> recentEarnings;
  final List<PayoutModel> payouts;
  final BankAccountModel? bankAccount;

  const EarningsDataLoaded({
    required this.summary,
    required this.recentEarnings,
    required this.payouts,
    this.bankAccount,
  });

  @override
  List<Object?> get props => [summary, recentEarnings, payouts, bankAccount];
}
