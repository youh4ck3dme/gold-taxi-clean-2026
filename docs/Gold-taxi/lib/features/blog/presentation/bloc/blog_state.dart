import 'package:equatable/equatable.dart';
import '../../../../models/post_model.dart';

abstract class BlogState extends Equatable {
  const BlogState();

  @override
  List<Object?> get props => [];
}

class BlogInitial extends BlogState {}

class BlogLoading extends BlogState {}

class BlogLoaded extends BlogState {
  final List<PostModel> posts;
  final bool hasReachedMax;

  const BlogLoaded({required this.posts, this.hasReachedMax = false});

  @override
  List<Object?> get props => [posts, hasReachedMax];
}

class BlogError extends BlogState {
  final String message;

  const BlogError(this.message);

  @override
  List<Object?> get props => [message];
}
