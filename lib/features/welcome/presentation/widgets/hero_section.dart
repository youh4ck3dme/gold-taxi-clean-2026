import 'package:flutter/material.dart';

/// Renders the Hero section with the logo and tagline for the Welcome screen.
class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFD166), Color(0xFFFFB629), Color(0xFF9B5C00)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB629).withValues(alpha: 0.32),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_taxi_rounded,
            color: Colors.black,
            size: 44,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Gold Taxi',
          style: theme.textTheme.displayMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: -2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Your ride, your way',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.85),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
