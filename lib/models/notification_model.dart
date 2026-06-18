import 'package:equatable/equatable.dart';

/// Resilient Notification Model representing system notifications
class NotificationModel extends Equatable {
  final int id;
  final String title;
  final String message;
  final DateTime date;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final jetMeta = json['jet_engine_meta'] as Map<String, dynamic>? ?? {};
    final acf = json['acf'] as Map<String, dynamic>? ?? {};

    T getField<T>(String key, T defaultValue) {
      return (json[key] ?? meta[key] ?? jetMeta[key] ?? acf[key]) as T? ??
          defaultValue;
    }

    String title = '';
    final titleObj = json['title'];
    if (titleObj is Map) {
      title = titleObj['rendered'] as String? ?? '';
    } else if (titleObj is String) {
      title = titleObj;
    }

    String message = getField<String>('message', '');
    if (message.isEmpty) {
      final contentObj = json['content'];
      message = contentObj is Map
          ? (contentObj['rendered'] as String? ?? '')
          : (contentObj as String? ?? '');
    }

    dynamic rawIsRead = getField<dynamic>('is_read', false);
    bool isRead = rawIsRead is bool
        ? rawIsRead
        : (rawIsRead.toString() == 'true' || rawIsRead.toString() == '1');

    return NotificationModel(
      id: json['id'] as int? ?? 0,
      title: title,
      message: message,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      isRead: isRead,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'date': date.toIso8601String(),
    'is_read': isRead,
  };

  @override
  List<Object?> get props => [id, title, message, date, isRead];
}
