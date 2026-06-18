import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gold_taxi/features/blog/presentation/bloc/blog_bloc.dart';
import 'package:gold_taxi/features/blog/presentation/bloc/blog_event.dart';
import 'package:gold_taxi/features/blog/presentation/bloc/blog_state.dart';
import 'package:gold_taxi/features/blog/data/repositories/blog_repository.dart';
import 'package:gold_taxi/models/post_model.dart';

class MockBlogRepository extends Mock implements BlogRepository {}

void main() {
  late BlogBloc blogBloc;
  late MockBlogRepository mockBlogRepository;

  setUp(() {
    mockBlogRepository = MockBlogRepository();
    blogBloc = BlogBloc(mockBlogRepository);
  });

  tearDown(() {
    blogBloc.close();
  });

  group('BlogBloc Tests', () {
    final testPost = PostModel(
      id: '1',
      date: DateTime(2026, 6, 11),
      title: 'Test Post Title',
      content: 'Test Post Content',
      excerpt: 'Test Post Excerpt',
      featuredImageUrl: null,
      authorName: 'Test Author',
      categories: const ['Test Category'],
      tags: const ['Test Tag'],
    );

    test('Initial state is BlogInitial', () {
      expect(blogBloc.state, isA<BlogInitial>());
    });

    test(
      'FetchPosts emits [BlogLoading, BlogLoaded] when repository succeeds',
      () async {
        when(
          () => mockBlogRepository.getPosts(
            page: any(named: 'page'),
            search: any(named: 'search'),
          ),
        ).thenAnswer((_) async => [testPost]);

        expectLater(
          blogBloc.stream,
          emitsInOrder([isA<BlogLoading>(), isA<BlogLoaded>()]),
        );

        blogBloc.add(const FetchPosts());
      },
    );

    test(
      'FetchPosts emits [BlogLoading, BlogError] when repository throws error',
      () async {
        when(
          () => mockBlogRepository.getPosts(
            page: any(named: 'page'),
            search: any(named: 'search'),
          ),
        ).thenThrow(Exception('API error'));

        expectLater(
          blogBloc.stream,
          emitsInOrder([isA<BlogLoading>(), isA<BlogError>()]),
        );

        blogBloc.add(const FetchPosts());
      },
    );
  });
}
