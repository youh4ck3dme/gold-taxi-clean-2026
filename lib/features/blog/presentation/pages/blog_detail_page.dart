import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../../../models/post_model.dart';

class BlogDetailPage extends StatelessWidget {
  final PostModel post;

  const BlogDetailPage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail článku'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (post.featuredImageUrl != null)
              Image.network(
                post.featuredImageUrl!,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Publikované: ${post.date.day}.${post.date.month}.${post.date.year}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const Divider(height: 32),
                  Html(
                    data: post.content,
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
