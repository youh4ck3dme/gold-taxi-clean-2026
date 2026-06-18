import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:gold_taxi/core/di/service_locator.dart';
import '../bloc/reviews_bloc.dart';
import '../bloc/reviews_event.dart';
import '../bloc/reviews_state.dart';
import 'rating_stars.dart';
import 'review_form.dart';

class ReviewsList extends StatelessWidget {
  final int postId;

  const ReviewsList({super.key, required this.postId});

  void _showAddReviewSheet(BuildContext context, ReviewsBloc reviewsBloc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return BlocProvider.value(
          value: reviewsBloc,
          child: ReviewForm(
            postId: postId,
            onSuccess: () {
              reviewsBloc.add(FetchReviews(postId));
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ReviewsBloc>()..add(FetchReviews(postId)),
      child: Builder(
        builder: (context) {
          final reviewsBloc = context.read<ReviewsBloc>();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Hodnotenia a Recenzie',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.rate_review, size: 18),
                    label: const Text('Pridať'),
                    onPressed: () => _showAddReviewSheet(context, reviewsBloc),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              BlocBuilder<ReviewsBloc, ReviewsState>(
                builder: (context, state) {
                  if (state is ReviewsLoading ||
                      state is ReviewSubmissionInProgress) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  } else if (state is ReviewsError) {
                    return Center(
                      child: Text(
                        'Chyba pri načítaní recenzií: ${state.message}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  } else if (state is ReviewsLoaded ||
                      state is ReviewSubmissionSuccess) {
                    final reviews = state is ReviewsLoaded
                        ? state.reviews
                        : (reviewsBloc.state as ReviewsLoaded).reviews;

                    if (reviews.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Zatiaľ žiadne hodnotenia. Buďte prvý, kto napíše recenziu!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reviews.length,
                      itemBuilder: (context, index) {
                        final review = reviews[index];
                        final dateStr = DateFormat(
                          'dd.MM.yyyy',
                        ).format(review.date);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[200]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      review.authorName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    dateStr,
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              RatingStars(
                                rating: review.rating.toDouble(),
                                size: 14,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                review.comment,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }
                  return const SizedBox();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
