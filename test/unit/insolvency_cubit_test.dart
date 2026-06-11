import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gold_taxi/features/insolvency_monitoring/presentation/cubits/insolvency_cubit.dart';
import 'package:gold_taxi/core/services/api_service.dart';
import 'package:gold_taxi/core/services/insolvency_predictor_service.dart';
import 'package:gold_taxi/models/invoice_model.dart';

class MockApiService extends Mock implements ApiService {}
class MockInsolvencyPredictorService extends Mock implements InsolvencyPredictorService {}

void main() {
  late InsolvencyCubit insolvencyCubit;
  late MockApiService mockApiService;
  late MockInsolvencyPredictorService mockPredictorService;

  setUp(() {
    mockApiService = MockApiService();
    mockPredictorService = MockInsolvencyPredictorService();
    insolvencyCubit = InsolvencyCubit(mockPredictorService, mockApiService);
  });

  tearDown(() {
    insolvencyCubit.close();
  });

  group('InsolvencyCubit Tests', () {
    final testInvoice = InvoiceModel(
      id: 'FA-1',
      amount: 100.0,
      issueDate: DateTime(2026, 5, 10),
      dueDate: DateTime(2026, 5, 24),
      paidDate: DateTime(2026, 5, 25),
    );

    const testPrediction = InsolvencyPrediction(
      riskScore: 10.0,
      riskLevel: 'Nízke',
      predictsInsolvencyIn3Months: false,
      riskFactors: ['Všetky platby sú načas.'],
      averageDelayDays: 1.0,
      delayTrend: 0.0,
      unpaidRatio: 0.0,
    );

    test('Initial state is InsolvencyInitial', () {
      expect(insolvencyCubit.state, isA<InsolvencyInitial>());
    });

    test('loadScenario for WordPress fetches real invoices and calls predictor service', () async {
      when(() => mockApiService.getInvoices()).thenAnswer((_) async => [testInvoice]);
      when(() => mockPredictorService.analyzeInsolvencyRisk(any(), evaluationDate: any(named: 'evaluationDate')))
          .thenReturn(testPrediction);

      expectLater(
        insolvencyCubit.stream,
        emitsInOrder([
          isA<InsolvencyLoading>(),
          isA<InsolvencyLoaded>(),
        ]),
      );

      await insolvencyCubit.loadScenario('Reálne dáta (WordPress)');
    });

    test('loadScenario for mock scenario loads mock data and calls predictor service', () async {
      when(() => mockPredictorService.analyzeInsolvencyRisk(any(), evaluationDate: any(named: 'evaluationDate')))
          .thenReturn(testPrediction);

      expectLater(
        insolvencyCubit.stream,
        emitsInOrder([
          isA<InsolvencyLoading>(),
          isA<InsolvencyLoaded>(),
        ]),
      );

      await insolvencyCubit.loadScenario('Nízke riziko (Dobrá platobná morálka)');
    });

    test('loadScenario emits InsolvencyError when WordPress fetch fails', () async {
      when(() => mockApiService.getInvoices()).thenThrow(Exception('Network error'));

      expectLater(
        insolvencyCubit.stream,
        emitsInOrder([
          isA<InsolvencyLoading>(),
          isA<InsolvencyError>(),
        ]),
      );

      await insolvencyCubit.loadScenario('Reálne dáta (WordPress)');
    });
  });
}
