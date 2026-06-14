import 'package:equatable/equatable.dart';

abstract class BlogEvent extends Equatable {
  const BlogEvent();

  @override
  List<Object?> get props => [];
}

class FetchPosts extends BlogEvent {
  final String? search;
  final bool isRefresh;

  const FetchPosts({this.search, this.isRefresh = false});

  @override
  List<Object?> get props => [search, isRefresh];
}
