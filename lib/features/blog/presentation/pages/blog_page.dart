import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/fields/app_text_field.dart';
import '../../../../core/widgets/loaders/shimmer_list_loader.dart';
import '../../../../models/post_model.dart';
import '../bloc/blog_bloc.dart';
import '../bloc/blog_event.dart';
import '../bloc/blog_state.dart';

class BlogPage extends StatefulWidget {
  const BlogPage({super.key});

  @override
  State<BlogPage> createState() => _BlogPageState();
}

class _BlogPageState extends State<BlogPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BlogBloc>()..add(const FetchPosts()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Blog & Novinky')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Builder(
                builder: (context) {
                  return AppTextField(
                    controller: _searchController,
                    labelText: 'Vyhľadať články',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        context.read<BlogBloc>().add(const FetchPosts());
                      },
                    ),
                    textInputAction: TextInputAction.search,
                    onFieldSubmitted: (value) {
                      context.read<BlogBloc>().add(FetchPosts(search: value));
                    },
                    validator: null,
                    hintText: 'Zadajte kľúčové slovo...',
                    keyboardType: TextInputType.text,
                  );
                },
              ),
            ),
            Expanded(
              child: BlocBuilder<BlogBloc, BlogState>(
                builder: (context, state) {
                  if (state is BlogLoading) {
                    return const ShimmerListLoader();
                  } else if (state is BlogError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Chyba: ${state.message}',
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<BlogBloc>().add(
                                FetchPosts(
                                  search: _searchController.text,
                                  isRefresh: true,
                                ),
                              );
                            },
                            child: const Text('Skúsiť znova'),
                          ),
                        ],
                      ),
                    );
                  } else if (state is BlogLoaded) {
                    final posts = state.posts;
                    if (posts.isEmpty) {
                      return const Center(
                        child: Text('Nenašli sa žiadne články.'),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<BlogBloc>().add(
                          FetchPosts(
                            search: _searchController.text,
                            isRefresh: true,
                          ),
                        );
                      },
                      child: ListView.builder(
                        itemCount: posts.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          return _PostCard(post: post);
                        },
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final PostModel post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () {
          context.push('/blog/detail', extra: post);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (post.featuredImageUrl != null)
              Image.network(
                post.featuredImageUrl!,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  height: 180,
                  child: Icon(Icons.image_not_supported, size: 50),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.excerpt.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ''),
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${post.date.day}.${post.date.month}.${post.date.year}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                      const Text(
                        'Čítať viac →',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
