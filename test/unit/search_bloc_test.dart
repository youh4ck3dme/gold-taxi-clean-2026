import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gold_taxi/features/search/presentation/bloc/search_bloc.dart';
import 'package:gold_taxi/features/search/presentation/bloc/search_event.dart';
import 'package:gold_taxi/features/search/presentation/bloc/search_state.dart';
import 'package:gold_taxi/features/search/data/repositories/search_repository.dart';

class MockSearchRepository extends Mock implements SearchRepository {}

void main() {
  late SearchBloc searchBloc;
  late MockSearchRepository mockSearchRepository;

  setUp(() {
    mockSearchRepository = MockSearchRepository();
    when(
      () => mockSearchRepository.getSearchHistory(),
    ).thenAnswer((_) async => <String>[]);
    searchBloc = SearchBloc(mockSearchRepository);
  });

  tearDown(() {
    searchBloc.close();
  });

  group('SearchBloc Tests', () {
    test('Initial state is SearchInitial with empty history', () {
      expect(searchBloc.state, isA<SearchInitial>());
      expect((searchBloc.state as SearchInitial).history, isEmpty);
    });

    test(
      'LoadSearchHistory emits SearchInitial with history when repository succeeds',
      () async {
        when(
          () => mockSearchRepository.getSearchHistory(),
        ).thenAnswer((_) async => ['shuttle', 'airport']);

        expectLater(searchBloc.stream, emitsInOrder([isA<SearchInitial>()]));

        searchBloc.add(LoadSearchHistory());
      },
    );

    test('SearchQueryChanged with empty query emits SearchInitial', () async {
      when(
        () => mockSearchRepository.getSearchHistory(),
      ).thenAnswer((_) async => []);

      expectLater(searchBloc.stream, emitsInOrder([isA<SearchInitial>()]));

      searchBloc.add(const SearchQueryChanged(''));
    });

    test(
      'SearchQueryChanged with query emits [SearchLoading, SearchSuccess] when repository succeeds',
      () async {
        when(
          () => mockSearchRepository.searchAll(any()),
        ).thenAnswer((_) async => const SearchResult());
        when(
          () => mockSearchRepository.addToSearchHistory(any()),
        ).thenAnswer((_) async => {});

        expectLater(
          searchBloc.stream,
          emitsInOrder([isA<SearchLoading>(), isA<SearchSuccess>()]),
        );

        searchBloc.add(const SearchQueryChanged('airport'));
      },
    );

    test('ClearHistory emits SearchInitial with empty list', () async {
      when(
        () => mockSearchRepository.clearSearchHistory(),
      ).thenAnswer((_) async => {});

      expectLater(searchBloc.stream, emitsInOrder([isA<SearchInitial>()]));

      searchBloc.add(ClearHistory());
    });
  });
}
