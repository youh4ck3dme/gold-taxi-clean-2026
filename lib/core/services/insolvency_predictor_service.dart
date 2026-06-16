import '../../models/invoice_model.dart';

class InsolvencyPrediction {
  final double riskScore; // 0.0 to 100.0
  final String riskLevel; // 'Nízke', 'Stredné', 'Vysoké'
  final double averageDelayDays;
  final double delayTrend; // Rozdiel v priemernom oneskorení (posledných 90 dní vs predchádzajúcich 90 dní)
  final double unpaidRatio; // Pomer neuhradených po splatnosti k celkovému objemu
  final List<String> riskFactors;
  final bool predictsInsolvencyIn3Months;

  const InsolvencyPrediction({
    required this.riskScore,
    required this.riskLevel,
    required this.averageDelayDays,
    required this.delayTrend,
    required this.unpaidRatio,
    required this.riskFactors,
    required this.predictsInsolvencyIn3Months,
  });
}

class InsolvencyPredictorService {
  /// Analyzuje platobnú morálku a generuje predikciu úpadku na 3 mesiace vopred
  InsolvencyPrediction analyzeInsolvencyRisk(List<InvoiceModel> invoices, {DateTime? evaluationDate}) {
    final now = evaluationDate ?? DateTime.now();
    final cutoff180 = now.subtract(const Duration(days: 180));
    final cutoff90 = now.subtract(const Duration(days: 90));

    // Filtrujeme faktúry za posledných 180 dní pre relevantnú analýzu platobnej morálky
    final relevantInvoices = invoices.where((inv) => inv.issueDate.isAfter(cutoff180)).toList();

    if (relevantInvoices.isEmpty) {
      return const InsolvencyPrediction(
        riskScore: 0.0,
        riskLevel: 'Nízke',
        averageDelayDays: 0.0,
        delayTrend: 0.0,
        unpaidRatio: 0.0,
        riskFactors: ['Nedostatok platobných údajov pre analýzu.'],
        predictsInsolvencyIn3Months: false,
      );
    }

    // 1. Objem fakturácie a neuhradené po splatnosti
    double totalInvoiced = 0.0;
    double totalOverdueUnpaid = 0.0;
    for (var inv in relevantInvoices) {
      totalInvoiced += inv.amount;
      if (inv.getStatus(now) == 'overdue') {
        totalOverdueUnpaid += inv.amount;
      }
    }
    final unpaidRatio = totalInvoiced > 0 ? (totalOverdueUnpaid / totalInvoiced) : 0.0;

    // 2. Rozdelenie do dvoch okien (Recent: 0-90 dní, Prior: 90-180 dní)
    final recentInvoices = relevantInvoices.where((inv) => inv.issueDate.isAfter(cutoff90)).toList();
    final priorInvoices = relevantInvoices.where((inv) => inv.issueDate.isBefore(cutoff90) || inv.issueDate.isAtSameMomentAs(cutoff90)).toList();

    double calculateAvgDelay(List<InvoiceModel> list) {
      if (list.isEmpty) return 0.0;
      double totalDelay = 0.0;
      for (var inv in list) {
        totalDelay += inv.getDelayDays(now);
      }
      return totalDelay / list.length;
    }

    final recentAvgDelay = calculateAvgDelay(recentInvoices);
    final priorAvgDelay = calculateAvgDelay(priorInvoices);
    final delayTrend = priorInvoices.isNotEmpty ? (recentAvgDelay - priorAvgDelay) : 0.0;

    // 3. Výpočet rizikového skóre (0 - 100)
    double riskScore = 0.0;

    // Váha za priemerné oneskorenie
    if (recentAvgDelay > 60) {
      riskScore += 40;
    } else if (recentAvgDelay > 30) {
      riskScore += 25;
    } else if (recentAvgDelay > 15) {
      riskScore += 10;
    }

    // Váha za pomer neuhradených po splatnosti
    if (unpaidRatio > 0.6) {
      riskScore += 45;
    } else if (unpaidRatio > 0.4) {
      riskScore += 30;
    } else if (unpaidRatio > 0.2) {
      riskScore += 15;
    } else if (unpaidRatio > 0.05) {
      riskScore += 5;
    }

    // Váha za zhoršujúci sa trend
    if (delayTrend > 15) {
      riskScore += 20;
    } else if (delayTrend > 5) {
      riskScore += 10;
    } else if (priorInvoices.isNotEmpty && delayTrend < -5 && unpaidRatio < 0.3) {
      riskScore -= 10; // Platby sú rýchlejšie (iba ak je nízky pomer neuhradených)
    }

    // Kritické oneskorenia (viac ako 90 dní po splatnosti voči evaluationDate)
    bool hasCriticallyOverdue = invoices.any((inv) => inv.getDelayDays(now) > 90);
    if (hasCriticallyOverdue) {
      riskScore += 10;
    }

    // Zaistenie hraníc
    riskScore = riskScore.clamp(0.0, 100.0);

    // 4. Vyhodnotenie úrovne rizika a predikcie úpadku
    String riskLevel = 'Nízke';
    bool predictsInsolvency = false;

    if (riskScore >= 70) {
      riskLevel = 'Vysoké';
      predictsInsolvency = true; // Skóre nad 70 predpovedá úpadok 3 mesiace vopred
    } else if (riskScore >= 35) {
      riskLevel = 'Stredné';
      // Ak oneskorenie drasticky rastie a pomer neuhradených je vysoký, predpovedáme insolvenciu
      if (delayTrend > 20 && unpaidRatio > 0.3) {
        predictsInsolvency = true;
      }
    }

    // 5. Zostavenie rizikových faktorov v slovenčine
    List<String> riskFactors = [];
    if (recentAvgDelay > 30) {
      riskFactors.add('Priemerné oneskorenie úhrad za posledných 90 dní je vysoké (${recentAvgDelay.toStringAsFixed(1)} dní).');
    }
    if (delayTrend > 5) {
      riskFactors.add('Trend platobnej morálky sa zhoršuje (oneskorenie vzrástlo o ${delayTrend.toStringAsFixed(1)} dní).');
    }
    if (unpaidRatio > 0.2) {
      riskFactors.add('Vysoký pomer neuhradených faktúr po splatnosti (${(unpaidRatio * 100).toStringAsFixed(0)}% z celkového objemu).');
    }
    if (hasCriticallyOverdue) {
      riskFactors.add('Evidujeme faktúry viac ako 90 dní po splatnosti.');
    }
    if (riskFactors.isEmpty) {
      riskFactors.add('Žiadne významné rizikové faktory. Platobná morálka je stabilná.');
    }

    return InsolvencyPrediction(
      riskScore: riskScore,
      riskLevel: riskLevel,
      averageDelayDays: recentAvgDelay,
      delayTrend: delayTrend,
      unpaidRatio: unpaidRatio,
      riskFactors: riskFactors,
      predictsInsolvencyIn3Months: predictsInsolvency,
    );
  }
}
