import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import '../cubits/earnings_cubit.dart';
import '../cubits/earnings_state.dart';
import '../widgets/bank_account_dialog.dart';
import '../../data/models/bank_account_model.dart';
import '../../data/models/earnings_model.dart';
import '../../data/models/payout_model.dart';
import '../../data/repositories/earnings_repository.dart';

/// Earnings Dashboard Page for Drivers
class EarningsPage extends StatelessWidget {
  const EarningsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _EarningsPageContent();
  }
}


class _EarningsPageContent extends StatefulWidget {
  const _EarningsPageContent();

  @override
  State<_EarningsPageContent> createState() => _EarningsPageContentState();
}

class _EarningsPageContentState extends State<_EarningsPageContent> {
  String _selectedPeriod = 'week';
  DateTimeRange? _selectedDateRange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zárobky'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _selectedDateRange = null;
              });
              context.read<EarningsCubit>().loadAllData();
            },
            tooltip: 'Obnoviť dáta',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<EarningsCubit>().loadAllData(
          fromDate: _selectedDateRange?.start,
          toDate: _selectedDateRange?.end,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Earnings Summary Cards
              BlocBuilder<EarningsCubit, EarningsState>(
                builder: (context, state) {
                  if (state is EarningsLoading) {
                    return const _LoadingCard();
                  } else if (state is EarningsDataLoaded) {
                    return _EarningsSummaryCards(summary: state.summary);
                  } else if (state is EarningsSummaryLoaded) {
                    return _EarningsSummaryCards(summary: state.summary);
                  } else if (state is EarningsError) {
                    return _ErrorCard(message: state.message);
                  }
                  return const _LoadingCard();
                },
              ),
              
              const SizedBox(height: 24),
              
              // Period Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPeriodChip('Dnes', 'today'),
                  const SizedBox(width: 8),
                  _buildPeriodChip('Týždeň', 'week'),
                  const SizedBox(width: 8),
                  _buildPeriodChip('Mesiac', 'month'),
                  const SizedBox(width: 8),
                  _buildPeriodChip('Všetko', 'all'),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Earnings Chart
              BlocBuilder<EarningsCubit, EarningsState>(
                builder: (context, state) {
                  if (state is EarningsLoading) {
                    return const _LoadingChart();
                  } else if (state is EarningsDataLoaded) {
                    return _EarningsChart(
                      earnings: state.recentEarnings,
                      selectedPeriod: _selectedPeriod,
                    );
                  } else if (state is EarningsSummaryLoaded) {
                    return _EarningsChart(
                      earnings: state.recentEarnings,
                      selectedPeriod: _selectedPeriod,
                    );
                  }
                  return const _LoadingChart();
                },
              ),
              
              const SizedBox(height: 24),
              
              // Recent Earnings Title & Date Range / CSV Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nedávne Zárobky',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _selectedDateRange != null 
                              ? Icons.date_range 
                              : Icons.date_range_outlined,
                          color: _selectedDateRange != null ? Colors.blue : Colors.black87,
                        ),
                        onPressed: _selectDateRange,
                        tooltip: 'Filtrovať podľa dátumu',
                      ),
                      if (_selectedDateRange != null)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _selectedDateRange = null;
                            });
                            context.read<EarningsCubit>().loadAllData();
                          },
                          tooltip: 'Zrušiť filter',
                        ),
                      BlocBuilder<EarningsCubit, EarningsState>(
                        builder: (context, state) {
                          final earnings = state is EarningsDataLoaded
                              ? state.recentEarnings
                              : (state is EarningsSummaryLoaded ? state.recentEarnings : <EarningsModel>[]);
                          
                          return IconButton(
                            icon: const Icon(Icons.download),
                            onPressed: earnings.isEmpty
                                ? null
                                : () => _exportToCsv(earnings),
                            tooltip: 'Exportovať do CSV',
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              if (_selectedDateRange != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Filter: ${DateFormat('dd.MM.yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd.MM.yyyy').format(_selectedDateRange!.end)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              
              BlocBuilder<EarningsCubit, EarningsState>(
                builder: (context, state) {
                  if (state is EarningsLoading) {
                    return const _LoadingList();
                  } else if (state is EarningsDataLoaded) {
                    return _EarningsList(earnings: state.recentEarnings);
                  } else if (state is EarningsSummaryLoaded) {
                    return _EarningsList(earnings: state.recentEarnings);
                  }
                  return const _LoadingList();
                },
              ),
              
              const SizedBox(height: 24),

              // Bank Account Section
              const Text(
                'Bankový účet pre výplaty',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              BlocBuilder<EarningsCubit, EarningsState>(
                builder: (context, state) {
                  if (state is EarningsLoading) {
                    return const _LoadingList();
                  } else if (state is EarningsDataLoaded) {
                    return _BankAccountCard(
                      bankAccount: state.bankAccount,
                      driverId: context.read<EarningsCubit>().driverId,
                    );
                  }
                  return const SizedBox();
                },
              ),
              
              const SizedBox(height: 24),
              
              // Payouts Section
              const Text(
                'Výplaty',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              
              BlocBuilder<EarningsCubit, EarningsState>(
                builder: (context, state) {
                  if (state is EarningsLoading) {
                    return const _LoadingList();
                  } else if (state is EarningsDataLoaded) {
                    return _PayoutsList(
                      payouts: state.payouts,
                      onRequestPayout: () => _showPayoutDialog(context),
                    );
                  } else if (state is PayoutsLoaded) {
                    return _PayoutsList(
                      payouts: state.payouts,
                      onRequestPayout: () => _showPayoutDialog(context),
                    );
                  }
                  return const _PayoutsList(payouts: [], onRequestPayout: null);
                },
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPayoutDialog(context),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        tooltip: 'Vyžiadať výplatu',
        child: const Icon(Icons.payment),
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedPeriod = value);
      },
      selectedColor: Colors.black,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black54,
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: Colors.grey[200],
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Future<void> _selectDateRange() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _selectedDateRange,
    );
    if (pickedRange != null) {
      setState(() => _selectedDateRange = pickedRange);
      if (mounted) {
        context.read<EarningsCubit>().loadAllData(
          fromDate: pickedRange.start,
          toDate: pickedRange.end,
        );
      }
    }
  }

  void _exportToCsv(List<EarningsModel> earnings) {
    final csvContent = StringBuffer();
    csvContent.writeln('ID jazdy;Dátum;Celková suma (€);Poplatok aplikácie (€);Čistý zárobok (€);Spôsob platby;Stav platby');
    
    final dateFormatter = DateFormat('dd.MM.yyyy HH:mm');
    
    for (final earning in earnings) {
      final methodText = earning.paymentMethod == PaymentMethod.cash 
          ? 'Hotovosť' 
          : (earning.paymentMethod == PaymentMethod.card ? 'Karta' : 'Stripe');
      final statusText = earning.paymentStatus == PaymentStatus.completed 
          ? 'Dokončené' 
          : 'Prebieha';
          
      csvContent.writeln(
        '${earning.rideId};'
        '${dateFormatter.format(earning.createdAt)};'
        '${earning.totalAmount.toStringAsFixed(2)};'
        '${earning.appFee.toStringAsFixed(2)};'
        '${earning.netAmount.toStringAsFixed(2)};'
        '$methodText;'
        '$statusText'
      );
    }
    
    final bytes = Uint8List.fromList(utf8.encode(csvContent.toString()));
    Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          name: 'export_zarobkov.csv',
          mimeType: 'text/csv',
        ),
      ],
      subject: 'Export zárobkov',
    );
  }

  void _showPayoutDialog(BuildContext context) {
    final cubit = context.read<EarningsCubit>();
    final currencyFormat = NumberFormat.currency(
      symbol: '€',
      decimalDigits: 2,
      locale: 'sk_SK',
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        final TextEditingController amountController = TextEditingController();
        final TextEditingController bankLast4Controller = TextEditingController();

        return AlertDialog(
          title: const Text('Vyžiadať Výplatu'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Zadajte čiastku na výplatu z vášho dostupného zostatku.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: 'Čiastok (€)',
                    hintText: 'Napr. 100.00',
                    prefixIcon: const Icon(Icons.euro),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bankLast4Controller,
                  decoration: InputDecoration(
                    labelText: 'Posledné 4 číslice bankového účtu (optional)',
                    hintText: 'Napr. 1234',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                ),
                const SizedBox(height: 16),
                BlocBuilder<EarningsCubit, EarningsState>(
                  builder: (blocContext, state) {
                    if (state is EarningsDataLoaded) {
                      return Text(
                        'Dostupné: ${currencyFormat.format(state.summary.today + state.summary.thisWeek + state.summary.thisMonth)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Zrušiť'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text.replaceAll(',', '.'));
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Zadajte platnú čiastku'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                await cubit.requestPayout(
                  amount: amount,
                  bankAccountLast4: bankLast4Controller.text.isNotEmpty 
                      ? bankLast4Controller.text 
                      : null,
                );

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: const Text('Vyžiadať'),
            ),
          ],
        );
      },
    );
  }
}

class _BankAccountCard extends StatelessWidget {
  final BankAccountModel? bankAccount;
  final String driverId;

  const _BankAccountCard({
    required this.bankAccount,
    required this.driverId,
  });

  @override
  Widget build(BuildContext context) {
    if (bankAccount == null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.account_balance, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'Nemáte pridaný bankový účet',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pridajte svoj bankový účet pre prijímanie platieb cez Stripe Connect.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _openBankAccountDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Pridať bankový účet'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.account_balance, size: 36, color: Colors.blue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bankAccount!.bankName ?? 'Neznáma banka',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Majiteľ: ${bankAccount!.accountHolderName ?? ""}',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  Text(
                    'Účet: **** **** **** ${bankAccount!.bankAccountLast4 ?? ""}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        bankAccount!.status == 'verified'
                            ? Icons.check_circle
                            : Icons.pending,
                        size: 14,
                        color: bankAccount!.status == 'verified'
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        bankAccount!.status == 'verified' ? 'Overený' : 'Čaká na overenie',
                        style: TextStyle(
                          fontSize: 11,
                          color: bankAccount!.status == 'verified'
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _openBankAccountDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black,
                elevation: 0,
              ),
              child: const Text('Upraviť'),
            ),
          ],
        ),
      ),
    );
  }

  void _openBankAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return BankAccountDialog(
          driverId: driverId,
          initialAccount: bankAccount,
          onSave: (newAccount) {
            context.read<EarningsCubit>().saveDriverBankAccount(newAccount);
          },
        );
      },
    );
  }
}

// ============= UI Components =============

class _EarningsSummaryCards extends StatelessWidget {
  final EarningsSummary summary;

  const _EarningsSummaryCards({required this.summary});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: '€',
      decimalDigits: 2,
      locale: 'sk_SK',
    );

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Dnes',
            amount: summary.today,
            currencyFormat: currencyFormat,
            color: Colors.blue,
            icon: Icons.today,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Týždeň',
            amount: summary.thisWeek,
            currencyFormat: currencyFormat,
            color: Colors.green,
            icon: Icons.calendar_view_week,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Mesiac',
            amount: summary.thisMonth,
            currencyFormat: currencyFormat,
            color: Colors.orange,
            icon: Icons.calendar_month,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final NumberFormat currencyFormat;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.currencyFormat,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormat.format(amount),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EarningsChart extends StatelessWidget {
  final List<EarningsModel> earnings;
  final String selectedPeriod;

  const _EarningsChart({
    required this.earnings,
    required this.selectedPeriod,
  });

  @override
  Widget build(BuildContext context) {
    if (earnings.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Žiadne dáta na zobrazenie',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Prepare chart data
    final spots = _prepareChartData();
    final maxY = _getMaxValue();

    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    final currencyFormat = NumberFormat.currency(
                      symbol: '€',
                      decimalDigits: 0,
                    );
                    return Text(
                      currencyFormat.format(value),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() < 0 || value.toInt() >= earnings.length) {
                      return const Text('');
                    }
                    final date = earnings[value.toInt()].createdAt;
                    final formatter = DateFormat.Md();
                    return Text(
                      formatter.format(date),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.blue,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.blue.withValues(alpha: 0.1),
                ),
                showingIndicators: [0],
              ),
            ],
            minY: 0,
            maxY: maxY * 1.2,
          ),
        ),
      ),
    );
  }

  List<FlSpot> _prepareChartData() {
    final List<FlSpot> spots = [];
    for (int i = 0; i < earnings.length; i++) {
      spots.add(FlSpot(i.toDouble(), earnings[i].netAmount));
    }
    return spots;
  }

  double _getMaxValue() {
    if (earnings.isEmpty) return 100;
    return earnings.map((e) => e.netAmount).reduce((a, b) => a > b ? a : b);
  }
}

class _EarningsList extends StatelessWidget {
  final List<EarningsModel> earnings;

  const _EarningsList({required this.earnings});

  @override
  Widget build(BuildContext context) {
    if (earnings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Žiadne nedávne zárobky',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final currencyFormat = NumberFormat.currency(
      symbol: '€',
      decimalDigits: 2,
      locale: 'sk_SK',
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: earnings.length,
          separatorBuilder: (context, index) => const Divider(height: 8),
          itemBuilder: (context, index) {
            final earning = earnings[index];
            return _EarningsListItem(
              earning: earning,
              currencyFormat: currencyFormat,
            );
          },
        ),
      ),
    );
  }
}

class _EarningsListItem extends StatelessWidget {
  final EarningsModel earning;
  final NumberFormat currencyFormat;

  const _EarningsListItem({
    required this.earning,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd. MM. yyyy');
    final timeFormatter = DateFormat('HH:mm');

    return InkWell(
      onTap: () => _showBreakdownDialog(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              earning.paymentMethod == PaymentMethod.cash 
                  ? Icons.money 
                  : Icons.credit_card,
              color: Colors.green,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jazda #${earning.rideId.substring(earning.rideId.length - 6)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${dateFormatter.format(earning.createdAt)} ${timeFormatter.format(earning.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(earning.netAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
                Text(
                  earning.paymentStatus.name,
                  style: TextStyle(
                    fontSize: 10,
                    color: earning.paymentStatus == PaymentStatus.completed 
                        ? Colors.green 
                        : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBreakdownDialog(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: '€',
      decimalDigits: 2,
      locale: 'sk_SK',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rozpad Zárobkov'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BreakdownRow(
              label: 'Celková suma (zákazník)',
              value: earning.totalAmount,
              currencyFormat: currencyFormat,
            ),
            _BreakdownRow(
              label: 'Poplatok aplikácie (${EarningsCubit.appFeePercentage}%)',
              value: earning.appFee,
              currencyFormat: currencyFormat,
              isFee: true,
            ),
            const Divider(),
            _BreakdownRow(
              label: 'Čistý zárobok (vám)',
              value: earning.netAmount,
              currencyFormat: currencyFormat,
              isHighlighted: true,
            ),
            const SizedBox(height: 8),
            Text(
              'Spôsob platby: ${_getPaymentMethodName(earning.paymentMethod)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Zavrieť'),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Hotovosť';
      case PaymentMethod.card:
        return 'Karta';
      case PaymentMethod.stripe:
        return 'Stripe';
    }
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final double value;
  final NumberFormat currencyFormat;
  final bool isFee;
  final bool isHighlighted;

  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.currencyFormat,
    this.isFee = false,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isFee ? Colors.red : Colors.black87,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            currencyFormat.format(value),
            style: TextStyle(
              color: isFee ? Colors.red : (isHighlighted ? Colors.green : Colors.black87),
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _PayoutsList extends StatelessWidget {
  final List<PayoutModel> payouts;
  final VoidCallback? onRequestPayout;

  const _PayoutsList({required this.payouts, this.onRequestPayout});

  @override
  Widget build(BuildContext context) {
    if (payouts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.receipt, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              const Text(
                'Žiadne výplaty',
                style: TextStyle(color: Colors.grey),
              ),
              if (onRequestPayout != null) ...[
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: onRequestPayout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Vyžiadať prvú výplatu'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final currencyFormat = NumberFormat.currency(
      symbol: '€',
      decimalDigits: 2,
      locale: 'sk_SK',
    );
    final dateFormatter = DateFormat('dd. MM. yyyy');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: payouts.length,
          separatorBuilder: (context, index) => const Divider(height: 8),
          itemBuilder: (context, index) {
            final payout = payouts[index];
            return ListTile(
              leading: Icon(
                _getPayoutStatusIcon(payout.status),
                color: _getPayoutStatusColor(payout.status),
              ),
              title: Text(
                currencyFormat.format(payout.amount),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status: ${_getPayoutStatusText(payout.status)}',
                    style: TextStyle(
                      color: _getPayoutStatusColor(payout.status),
                    ),
                  ),
                  Text(
                    'Dátum: ${dateFormatter.format(payout.requestedAt)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              trailing: payout.stripePayoutId != null
                  ? Text(
                      'Stripe: ${payout.stripePayoutId!.substring(payout.stripePayoutId!.length - 8)}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    )
                  : null,
            );
          },
        ),
      ),
    );
  }

  IconData _getPayoutStatusIcon(PayoutStatus status) {
    switch (status) {
      case PayoutStatus.paid:
        return Icons.check_circle;
      case PayoutStatus.inTransit:
        return Icons.sync;
      case PayoutStatus.pending:
        return Icons.pending;
      case PayoutStatus.failed:
        return Icons.error;
      case PayoutStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getPayoutStatusColor(PayoutStatus status) {
    switch (status) {
      case PayoutStatus.paid:
        return Colors.green;
      case PayoutStatus.inTransit:
        return Colors.blue;
      case PayoutStatus.pending:
        return Colors.orange;
      case PayoutStatus.failed:
        return Colors.red;
      case PayoutStatus.cancelled:
        return Colors.grey;
    }
  }

  String _getPayoutStatusText(PayoutStatus status) {
    switch (status) {
      case PayoutStatus.paid:
        return 'Vyplatené';
      case PayoutStatus.inTransit:
        return 'Spracovava sa';
      case PayoutStatus.pending:
        return 'Čaká sa';
      case PayoutStatus.failed:
        return 'Zlyhanie';
      case PayoutStatus.cancelled:
        return 'Zrušené';
    }
  }
}

// ============= Loading & Error States =============

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingChart extends StatelessWidget {
  const _LoadingChart();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            onPressed: () => context.read<EarningsCubit>().loadAllData(),
          ),
        ],
      ),
    );
  }
}
