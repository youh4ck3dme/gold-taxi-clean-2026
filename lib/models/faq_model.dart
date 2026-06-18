import 'package:equatable/equatable.dart';

class FaqModel extends Equatable {
  final String id;
  final String question;
  final String answer;
  final String category;

  const FaqModel({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
  });

  factory FaqModel.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final jetMeta = json['jet_engine_meta'] as Map<String, dynamic>? ?? {};
    final acf = json['acf'] as Map<String, dynamic>? ?? {};

    T getField<T>(String key, T defaultValue) {
      return (json[key] ?? meta[key] ?? jetMeta[key] ?? acf[key]) as T? ??
          defaultValue;
    }

    String question = getField<String>('question', '');
    if (question.isEmpty) {
      final titleObj = json['title'];
      question = titleObj is Map
          ? (titleObj['rendered'] as String? ?? '')
          : (titleObj as String? ?? '');
    }

    String answer = getField<String>('answer', '');
    if (answer.isEmpty) {
      final contentObj = json['content'];
      answer = contentObj is Map
          ? (contentObj['rendered'] as String? ?? '')
          : (contentObj as String? ?? '');
    }

    return FaqModel(
      id: json['id']?.toString() ?? '',
      question: question,
      answer: answer,
      category: getField<String>('category', 'Všeobecné'),
    );
  }

  factory FaqModel.fromSupabaseJson(Map<String, dynamic> json) {
    return FaqModel(
      id: json['id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      category: json['category'] as String? ?? 'Všeobecné',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'question': question,
    'answer': answer,
    'category': category,
  };

  @override
  List<Object?> get props => [id, question, answer, category];
}
