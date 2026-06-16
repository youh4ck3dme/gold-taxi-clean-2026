import 'package:equatable/equatable.dart';

class InvoiceModel extends Equatable {
  final String id;
  final double amount;
  final DateTime issueDate;
  final DateTime dueDate;
  final DateTime? paidDate;

  const InvoiceModel({
    required this.id,
    required this.amount,
    required this.issueDate,
    required this.dueDate,
    this.paidDate,
  });

  /// Vypočíta status faktúry dynamicky na základe splatnosti a dátumu úhrady voči zadanému dátumu vyhodnotenia
  String getStatus(DateTime evaluationDate) {
    if (paidDate != null && (paidDate!.isBefore(evaluationDate) || paidDate!.isAtSameMomentAs(evaluationDate))) {
      return 'paid';
    }
    if (evaluationDate.isAfter(dueDate)) {
      return 'overdue';
    }
    return 'unpaid';
  }

  /// Počet dní oneskorenia úhrady voči zadanému dátumu vyhodnotenia
  int getDelayDays(DateTime evaluationDate) {
    final isPaidAtEval = paidDate != null && (paidDate!.isBefore(evaluationDate) || paidDate!.isAtSameMomentAs(evaluationDate));
    if (isPaidAtEval) {
      if (paidDate!.isAfter(dueDate)) {
        return paidDate!.difference(dueDate).inDays;
      }
      return 0;
    }
    // Neuhradená k dátumu vyhodnotenia
    if (evaluationDate.isAfter(dueDate)) {
      return evaluationDate.difference(dueDate).inDays;
    }
    return 0;
  }

  /// Vypočíta status faktúry dynamicky na základe splatnosti a dátumu úhrady (k dnešnému dňu)
  String get status => getStatus(DateTime.now());

  /// Počet dní oneskorenia úhrady (alebo oneskorenia voči dnešku ak je po splatnosti a neuhradená)
  int get delayDays => getDelayDays(DateTime.now());

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final jetMeta = json['jet_engine_meta'] as Map<String, dynamic>? ?? {};
    final acf = json['acf'] as Map<String, dynamic>? ?? {};

    dynamic getField(String key) {
      return json[key] ?? meta[key] ?? jetMeta[key] ?? acf[key];
    }

    final rawId = json['id'] ?? getField('id') ?? '';
    final id = rawId.toString();

    final rawAmount = getField('amount');
    final amount = double.tryParse(rawAmount?.toString() ?? '') ?? 0.0;

    final rawIssueDate = getField('issue_date') ?? json['date'] ?? '';
    final issueDate = DateTime.tryParse(rawIssueDate.toString()) ?? DateTime.now();

    final rawDueDate = getField('due_date') ?? '';
    final dueDate = DateTime.tryParse(rawDueDate.toString()) ?? issueDate.add(const Duration(days: 14));

    final rawPaidDate = getField('paid_date');
    final paidDate = (rawPaidDate != null && rawPaidDate.toString().isNotEmpty)
        ? DateTime.tryParse(rawPaidDate.toString())
        : null;

    return InvoiceModel(
      id: id,
      amount: amount,
      issueDate: issueDate,
      dueDate: dueDate,
      paidDate: paidDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'issue_date': issueDate.toIso8601String(),
    'due_date': dueDate.toIso8601String(),
    'paid_date': paidDate?.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, amount, issueDate, dueDate, paidDate];
}
