import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gold_taxi/features/faq/presentation/bloc/faq_bloc.dart';
import 'package:gold_taxi/features/faq/presentation/bloc/faq_event.dart';
import 'package:gold_taxi/features/faq/presentation/bloc/faq_state.dart';
import 'package:gold_taxi/features/faq/data/repositories/faq_repository.dart';
import 'package:gold_taxi/models/faq_model.dart';

class MockFaqRepository extends Mock implements FaqRepository {}

void main() {
  late FaqBloc faqBloc;
  late MockFaqRepository mockFaqRepository;

  setUp(() {
    mockFaqRepository = MockFaqRepository();
    faqBloc = FaqBloc(mockFaqRepository);
  });

  tearDown(() {
    faqBloc.close();
  });

  group('FaqBloc Tests', () {
    const testFaq = FaqModel(
      id: 1,
      question: 'How to pay?',
      answer: 'You can pay by card or cash.',
      category: 'Payments',
    );

    test('Initial state is FaqInitial', () {
      expect(faqBloc.state, isA<FaqInitial>());
    });

    test('FetchFaqs emits [FaqLoading, FaqLoaded] when repository succeeds', () async {
      when(() => mockFaqRepository.getFaqs())
          .thenAnswer((_) async => [testFaq]);

      expectLater(
        faqBloc.stream,
        emitsInOrder([
          isA<FaqLoading>(),
          isA<FaqLoaded>(),
        ]),
      );

      faqBloc.add(const FetchFaqs());
    });

    test('FetchFaqs emits [FaqLoading, FaqError] when repository fails', () async {
      when(() => mockFaqRepository.getFaqs())
          .thenThrow(Exception('API error'));

      expectLater(
        faqBloc.stream,
        emitsInOrder([
          isA<FaqLoading>(),
          isA<FaqError>(),
        ]),
      );

      faqBloc.add(const FetchFaqs());
    });
  });
}
