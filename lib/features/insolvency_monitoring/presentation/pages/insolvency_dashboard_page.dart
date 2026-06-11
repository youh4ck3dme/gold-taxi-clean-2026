import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubits/insolvency_cubit.dart';
import '../../../../models/invoice_model.dart';
import '../../../../core/services/insolvency_predictor_service.dart';
import '../../../../core/di/service_locator.dart';

class InsolvencyDashboardPage extends StatelessWidget {
  const InsolvencyDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => getIt<InsolvencyCubit>()..loadScenario('Nízke riziko (Dobrá platobná morálka)'),
      child: Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Monitoring úpadku', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          elevation: 0,
          foregroundColor: isDarkMode ? Colors.white : Colors.black,
        ),
        body: BlocBuilder<InsolvencyCubit, InsolvencyState>(
          builder: (context, state) {
            if (state is InsolvencyLoading) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF4285F4)));
            }

            if (state is InsolvencyError) {
              return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
            }

            if (state is InsolvencyLoaded) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Scenario Selector
                    _buildScenarioSelector(context, state.activeScenario),
                    const SizedBox(height: 20),

                    // Risk Summary Card
                    _buildRiskCard(context, state.prediction),
                    const SizedBox(height: 20),

                    // Statistics Grid
                    _buildStatsGrid(context, state.prediction),
                    const SizedBox(height: 20),

                    // Risk Factors Card
                    _buildRiskFactorsCard(context, state.prediction),
                    const SizedBox(height: 20),

                    // Invoices List
                    _buildInvoicesList(context, state.invoices),
                  ],
                ),
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildScenarioSelector(BuildContext context, String currentScenario) {
    final scenarios = [
      'Nízke riziko (Dobrá platobná morálka)',
      'Zhoršujúci sa trend (Varovné signály)',
      'Vysoké riziko (Hroziaca insolvencia)',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentScenario,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF4285F4)),
          items: scenarios.map((s) {
            return DropdownMenuItem<String>(
              value: s,
              child: Text(
                s,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              context.read<InsolvencyCubit>().loadScenario(val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildRiskCard(BuildContext context, InsolvencyPrediction pred) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color riskColor;
    Color bgGradientStart;
    Color bgGradientEnd;

    switch (pred.riskLevel) {
      case 'Vysoké':
        riskColor = const Color(0xFFEF4444);
        bgGradientStart = const Color(0xFFFCA5A5).withValues(alpha: 0.15);
        bgGradientEnd = const Color(0xFFEF4444).withValues(alpha: 0.05);
        break;
      case 'Stredné':
        riskColor = const Color(0xFFF59E0B);
        bgGradientStart = const Color(0xFFFDE047).withValues(alpha: 0.15);
        bgGradientEnd = const Color(0xFFF59E0B).withValues(alpha: 0.05);
        break;
      default:
        riskColor = const Color(0xFF10B981);
        bgGradientStart = const Color(0xFF6EE7B7).withValues(alpha: 0.15);
        bgGradientEnd = const Color(0xFF10B981).withValues(alpha: 0.05);
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgGradientStart, bgGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: riskColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: riskColor.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Riziko úpadku (insolvencie)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${pred.riskLevel} riziko',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: riskColor,
                    ),
                  ),
                ],
              ),
              // Gauge / Circle Indicator
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: CircularProgressIndicator(
                      value: pred.riskScore / 100,
                      strokeWidth: 8,
                      backgroundColor: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      color: riskColor,
                    ),
                  ),
                  Text(
                    '${pred.riskScore.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (pred.predictsInsolvencyIn3Months) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.redAccent, thickness: 0.5),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.warning_rounded, color: Color(0xFFEF4444), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '🚨 Upozornenie: Predikcia indikuje vysokú pravdepodobnosť platobnej neschopnosti v nasledujúcich 3 mesiacoch (90 dňoch).',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, InsolvencyPrediction pred) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildStatCard(
              context: context,
              width: width,
              title: 'Priemerné oneskorenie',
              value: '${pred.averageDelayDays.toStringAsFixed(1)} dní',
              icon: Icons.timer_outlined,
              color: Colors.blueAccent,
            ),
            _buildStatCard(
              context: context,
              width: width,
              title: 'Trend splátok (90d)',
              value: '${pred.delayTrend > 0 ? '+' : ''}${pred.delayTrend.toStringAsFixed(1)} dní',
              icon: pred.delayTrend > 0 ? Icons.trending_up : Icons.trending_down,
              color: pred.delayTrend > 5
                  ? const Color(0xFFEF4444)
                  : (pred.delayTrend < -5 ? const Color(0xFF10B981) : Colors.amber),
            ),
            _buildStatCard(
              context: context,
              width: width,
              title: 'Pomer po splatnosti',
              value: '${(pred.unpaidRatio * 100).toStringAsFixed(0)}%',
              icon: Icons.pie_chart_outline,
              color: Colors.purple,
            ),
            _buildStatCard(
              context: context,
              width: width,
              title: 'Časový horizont',
              value: '3 mesiace',
              icon: Icons.calendar_month_outlined,
              color: Colors.teal,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required double width,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskFactorsCard(BuildContext context, InsolvencyPrediction pred) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hlavné rizikové faktory',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...pred.riskFactors.map((factor) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    pred.riskLevel == 'Vysoké' ? Icons.warning_amber_rounded : Icons.info_outline,
                    color: pred.riskLevel == 'Vysoké' ? Colors.redAccent : Colors.blueAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      factor,
                      style: const TextStyle(fontSize: 14, height: 1.3),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInvoicesList(BuildContext context, List<InvoiceModel> invoices) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'História fakturácie',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: invoices.length,
          itemBuilder: (context, index) {
            final inv = invoices[index];
            Color statusColor;
            String statusText;

            switch (inv.status) {
              case 'paid':
                statusColor = const Color(0xFF10B981);
                statusText = 'Uhradené';
                break;
              case 'overdue':
                statusColor = const Color(0xFFEF4444);
                statusText = 'Po splatnosti';
                break;
              default:
                statusColor = Colors.grey;
                statusText = 'Čaká na úhradu';
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv.id,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Splatnosť: ${DateFormat('dd.MM.yyyy').format(inv.dueDate)}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12.5),
                      ),
                      if (inv.paidDate != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Uhradené: ${DateFormat('dd.MM.yyyy').format(inv.paidDate!)}',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12.5),
                        ),
                      ],
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${inv.amount.toStringAsFixed(2)} €',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (inv.delayDays > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Oneskorenie: ${inv.delayDays} dní',
                          style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
