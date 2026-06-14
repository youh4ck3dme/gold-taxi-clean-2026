import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/insolvency_predictor_service.dart';
import '../../../../models/invoice_model.dart';

// States
abstract class InsolvencyState extends Equatable {
  const InsolvencyState();

  @override
  List<Object?> get props => [];
}

class InsolvencyInitial extends InsolvencyState {}

class InsolvencyLoading extends InsolvencyState {}

class InsolvencyLoaded extends InsolvencyState {
  final List<InvoiceModel> invoices;
  final InsolvencyPrediction prediction;
  final String activeScenario;

  const InsolvencyLoaded({
    required this.invoices,
    required this.prediction,
    required this.activeScenario,
  });

  @override
  List<Object?> get props => [invoices, prediction, activeScenario];
}

class InsolvencyError extends InsolvencyState {
  final String message;

  const InsolvencyError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class InsolvencyCubit extends Cubit<InsolvencyState> {
  final InsolvencyPredictorService _predictorService;
  final ApiService _apiService;

  InsolvencyCubit(this._predictorService, this._apiService) : super(InsolvencyInitial());

  /// Načíta platobné dáta pre vybraný scenár (alebo reálne dáta z WordPress)
  Future<void> loadScenario(String scenarioName) async {
    emit(InsolvencyLoading());
    try {
      List<InvoiceModel> invoices;
      if (scenarioName == 'Reálne dáta (WordPress)') {
        invoices = await _apiService.getInvoices();
      } else {
        invoices = _getMockInvoicesForScenario(scenarioName);
      }
      final prediction = _predictorService.analyzeInsolvencyRisk(invoices);
      emit(InsolvencyLoaded(
        invoices: invoices,
        prediction: prediction,
        activeScenario: scenarioName,
      ));
    } catch (e) {
      emit(InsolvencyError('Nepodarilo sa načítať dáta: $e'));
    }
  }

  List<InvoiceModel> _getMockInvoicesForScenario(String scenario) {
    final now = DateTime.now();

    switch (scenario) {
      case 'Nízke riziko (Dobrá platobná morálka)':
        return [
          InvoiceModel(
            id: 'FA-2026-001',
            amount: 1200.00,
            issueDate: now.subtract(const Duration(days: 170)),
            dueDate: now.subtract(const Duration(days: 156)),
            paidDate: now.subtract(const Duration(days: 154)), // 2 dni oneskorenie
          ),
          InvoiceModel(
            id: 'FA-2026-002',
            amount: 1450.00,
            issueDate: now.subtract(const Duration(days: 140)),
            dueDate: now.subtract(const Duration(days: 126)),
            paidDate: now.subtract(const Duration(days: 121)), // 5 dní oneskorenie
          ),
          InvoiceModel(
            id: 'FA-2026-003',
            amount: 1100.00,
            issueDate: now.subtract(const Duration(days: 110)),
            dueDate: now.subtract(const Duration(days: 96)),
            paidDate: now.subtract(const Duration(days: 95)), // 1 deň oneskorenie
          ),
          InvoiceModel(
            id: 'FA-2026-004',
            amount: 1300.00,
            issueDate: now.subtract(const Duration(days: 80)),
            dueDate: now.subtract(const Duration(days: 66)),
            paidDate: now.subtract(const Duration(days: 64)), // 2 dni oneskorenie
          ),
          InvoiceModel(
            id: 'FA-2026-005',
            amount: 1500.00,
            issueDate: now.subtract(const Duration(days: 50)),
            dueDate: now.subtract(const Duration(days: 36)),
            paidDate: now.subtract(const Duration(days: 35)), // 1 deň oneskorenie
          ),
          InvoiceModel(
            id: 'FA-2026-006',
            amount: 1600.00,
            issueDate: now.subtract(const Duration(days: 20)),
            dueDate: now.subtract(const Duration(days: 6)),
            paidDate: null, // Ešte neuhrazená, ale v splatnosti
          ),
        ];

      case 'Zhoršujúci sa trend (Varovné signály)':
        return [
          InvoiceModel(
            id: 'FA-2026-101',
            amount: 800.00,
            issueDate: now.subtract(const Duration(days: 170)),
            dueDate: now.subtract(const Duration(days: 156)),
            paidDate: now.subtract(const Duration(days: 155)), // 1 deň oneskorenie
          ),
          InvoiceModel(
            id: 'FA-2026-102',
            amount: 950.00,
            issueDate: now.subtract(const Duration(days: 140)),
            dueDate: now.subtract(const Duration(days: 126)),
            paidDate: now.subtract(const Duration(days: 121)), // 5 dní oneskorenie
          ),
          InvoiceModel(
            id: 'FA-2026-103',
            amount: 1100.00,
            issueDate: now.subtract(const Duration(days: 110)),
            dueDate: now.subtract(const Duration(days: 96)),
            paidDate: now.subtract(const Duration(days: 81)), // 15 dní oneskorenie
          ),
          InvoiceModel(
            id: 'FA-2026-104',
            amount: 1250.00,
            issueDate: now.subtract(const Duration(days: 80)),
            dueDate: now.subtract(const Duration(days: 66)),
            paidDate: now.subtract(const Duration(days: 36)), // 30 dní oneskorenie
          ),
          InvoiceModel(
            id: 'FA-2026-105',
            amount: 1400.00,
            issueDate: now.subtract(const Duration(days: 50)),
            dueDate: now.subtract(const Duration(days: 36)),
            paidDate: null, // Neuhradená, 36 dní po splatnosti
          ),
          InvoiceModel(
            id: 'FA-2026-106',
            amount: 1350.00,
            issueDate: now.subtract(const Duration(days: 20)),
            dueDate: now.subtract(const Duration(days: 6)),
            paidDate: null, // Neuhradená, 6 dní po splatnosti
          ),
        ];

      case 'Vysoké riziko (Hroziaca insolvencia)':
        return [
          InvoiceModel(
            id: 'FA-2026-201',
            amount: 2000.00,
            issueDate: now.subtract(const Duration(days: 170)),
            dueDate: now.subtract(const Duration(days: 156)),
            paidDate: now.subtract(const Duration(days: 126)), // 30 dní oneskorenie
          ),
          InvoiceModel(
            id: 'FA-2026-202',
            amount: 2500.00,
            issueDate: now.subtract(const Duration(days: 140)),
            dueDate: now.subtract(const Duration(days: 126)),
            paidDate: null, // Neuhradená, 126 dní po splatnosti (Kritické)
          ),
          InvoiceModel(
            id: 'FA-2026-203',
            amount: 1800.00,
            issueDate: now.subtract(const Duration(days: 110)),
            dueDate: now.subtract(const Duration(days: 96)),
            paidDate: null, // Neuhradená, 96 dní po splatnosti (Kritické)
          ),
          InvoiceModel(
            id: 'FA-2026-204',
            amount: 2200.00,
            issueDate: now.subtract(const Duration(days: 80)),
            dueDate: now.subtract(const Duration(days: 66)),
            paidDate: null, // Neuhradená, 66 dní po splatnosti
          ),
          InvoiceModel(
            id: 'FA-2026-205',
            amount: 3000.00,
            issueDate: now.subtract(const Duration(days: 50)),
            dueDate: now.subtract(const Duration(days: 36)),
            paidDate: null, // Neuhradená, 36 dní po splatnosti
          ),
          InvoiceModel(
            id: 'FA-2026-206',
            amount: 2800.00,
            issueDate: now.subtract(const Duration(days: 20)),
            dueDate: now.subtract(const Duration(days: 6)),
            paidDate: null, // Neuhradená, 6 dní po splatnosti
          ),
        ];

      default:
        return [];
    }
  }
}
