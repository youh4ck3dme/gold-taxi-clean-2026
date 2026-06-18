import 'package:flutter/material.dart';

class AnimatedPriceText extends StatelessWidget {
  final double value;
  final TextStyle style;

  const AnimatedPriceText({
    super.key,
    required this.value,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuint,
      builder: (context, animatedValue, child) {
        return Text("${animatedValue.toStringAsFixed(2)} €", style: style);
      },
    );
  }
}
