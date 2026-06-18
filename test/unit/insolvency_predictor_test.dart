import 'package:flutter_test/flutter_test.dart';
import 'package:gold_taxi/models/invoice_model.dart';
import 'package:gold_taxi/core/services/insolvency_predictor_service.dart';

void main() {
  group('InsolvencyPredictorService Tests', () {
    late InsolvencyPredictorService predictorService;
    final now = DateTime(2026, 6, 11, 12, 0, 0);

    setUp(() {
      predictorService = InsolvencyPredictorService();
    });

    test('Dobrá platobná morálka vyhodnotí nízke riziko', () {
      final invoices = [
        InvoiceModel(
          id: 'FA-1',
          amount: 1000.0,
          issueDate: now.subtract(const Duration(days: 150)),
          dueDate: now.subtract(const Duration(days: 140)),
          paidDate: now.subtract(
            const Duration(days: 139),
          ), // 1 deň oneskorenie
        ),
        InvoiceModel(
          id: 'FA-2',
          amount: 1200.0,
          issueDate: now.subtract(const Duration(days: 90)),
          dueDate: now.subtract(const Duration(days: 80)),
          paidDate: now.subtract(const Duration(days: 78)), // 2 dni oneskorenie
        ),
        InvoiceModel(
          id: 'FA-3',
          amount: 1500.0,
          issueDate: now.subtract(const Duration(days: 30)),
          dueDate: now.subtract(const Duration(days: 20)),
          paidDate: now.subtract(const Duration(days: 19)), // 1 deň oneskorenie
        ),
      ];

      final prediction = predictorService.analyzeInsolvencyRisk(
        invoices,
        evaluationDate: now,
      );

      expect(prediction.riskLevel, 'Nízke');
      expect(prediction.riskScore, lessThan(35.0));
      expect(prediction.predictsInsolvencyIn3Months, isFalse);
      expect(prediction.averageDelayDays, 1.0);
    });

    test(
      'Oneskorené platby a veľa otvorených faktúr vyhodnotí vysoké riziko úpadku',
      () {
        final invoices = [
          InvoiceModel(
            id: 'FA-11',
            amount: 1000.0,
            issueDate: now.subtract(const Duration(days: 150)),
            dueDate: now.subtract(const Duration(days: 140)),
            paidDate: now.subtract(
              const Duration(days: 100),
            ), // 40 dní oneskorenie
          ),
          InvoiceModel(
            id: 'FA-12',
            amount: 2000.0,
            issueDate: now.subtract(const Duration(days: 110)),
            dueDate: now.subtract(const Duration(days: 100)),
            paidDate: null, // Neuhradená, 100 dní po splatnosti (Kritické)
          ),
          InvoiceModel(
            id: 'FA-13',
            amount: 2500.0,
            issueDate: now.subtract(const Duration(days: 60)),
            dueDate: now.subtract(const Duration(days: 50)),
            paidDate: null, // Neuhradená, 50 dní po splatnosti
          ),
        ];

        final prediction = predictorService.analyzeInsolvencyRisk(
          invoices,
          evaluationDate: now,
        );

        expect(prediction.riskLevel, 'Vysoké');
        expect(prediction.riskScore, greaterThanOrEqualTo(70.0));
        expect(prediction.predictsInsolvencyIn3Months, isTrue);
        expect(
          prediction.riskFactors,
          contains(contains('faktúry viac ako 90 dní po splatnosti')),
        );
      },
    );

    test('Prázdny zoznam faktúr vráti nízke riziko s vysvetlením', () {
      final prediction = predictorService.analyzeInsolvencyRisk(
        [],
        evaluationDate: now,
      );

      expect(prediction.riskLevel, 'Nízke');
      expect(prediction.riskScore, 0.0);
      expect(prediction.predictsInsolvencyIn3Months, isFalse);
      expect(
        prediction.riskFactors.first,
        contains('Nedostatok platobných údajov'),
      );
    });
  });
}
