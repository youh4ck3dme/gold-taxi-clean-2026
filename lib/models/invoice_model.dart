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

  /// Vypočíta status faktúry dynamicky na základe splatnosti a dátumu úhrady
  String get status {
    if (paidDate != null) {
      return 'paid';
    }
    if (DateTime.now().isAfter(dueDate)) {
      return 'overdue';
    }
    return 'unpaid';
  }

  /// Počet dní oneskorenia úhrady (alebo oneskorenia voči dnešku ak je po splatnosti a neuhradená)
  int get delayDays {
    if (paidDate != null) {
      if (paidDate!.isAfter(dueDate)) {
        return paidDate!.difference(dueDate).inDays;
      }
      return 0;
    }
    if (DateTime.now().isAfter(dueDate)) {
      return DateTime.now().difference(dueDate).inDays;
    }
    return 0;
  }

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] as String? ?? '',
      amount: (json['amount'] as num? ?? 0.0).toDouble(),
      issueDate: DateTime.parse(json['issue_date'] as String),
      dueDate: DateTime.parse(json['due_date'] as String),
      paidDate: json['paid_date'] != null ? DateTime.parse(json['paid_date'] as String) : null,
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
