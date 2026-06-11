import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/blog_repository.dart';
import 'blog_event.dart';
import 'blog_state.dart';

class BlogBloc extends Bloc<BlogEvent, BlogState> {
  final BlogRepository _blogRepository;

  BlogBloc(this._blogRepository) : super(BlogInitial()) {
    on<FetchPosts>(_onFetchPosts);
  }

  Future<void> _onFetchPosts(FetchPosts event, Emitter<BlogState> emit) async {
    if (state is! BlogLoaded || event.isRefresh || event.search != null) {
      emit(BlogLoading());
    }

    try {
      final posts = await _blogRepository.getPosts(
        page: 1,
        search: event.search,
      );
      emit(BlogLoaded(posts: posts, hasReachedMax: true));
    } catch (e) {
      emit(BlogError(e.toString()));
    }
  }
}
