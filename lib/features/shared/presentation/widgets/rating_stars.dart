import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final ValueChanged<int>? onRatingChanged;
  final Color color;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 20,
    this.onRatingChanged,
    this.color = Colors.amber,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        IconData iconData;
        if (onRatingChanged != null) {
          iconData = starIndex <= rating.round()
              ? Icons.star
              : Icons.star_border;
          return IconButton(
            icon: Icon(iconData, color: color, size: size),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => onRatingChanged!(starIndex),
          );
        } else {
          if (rating >= starIndex) {
            iconData = Icons.star;
          } else if (rating >= starIndex - 0.5) {
            iconData = Icons.star_half;
          } else {
            iconData = Icons.star_border;
          }
          return Icon(iconData, color: color, size: size);
        }
      }),
    );
  }
}
