import 'package:flutter/material.dart';

/// Renders the statistics and links at the bottom of the welcome screen.
class StatsSection extends StatelessWidget {
  const StatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const _StatItem(value: '10k+', label: 'Rides'),
            Container(width: 1, height: 32, color: Colors.white24),
            const _StatItem(value: '4.9/5', label: 'Rating', icon: Icons.star),
            Container(width: 1, height: 32, color: Colors.white24),
            const _StatItem(value: '24/7', label: 'Support'),
          ],
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {},
              child: Text(
                'FAQ',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              ),
            ),
            Text(
              '•',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'Terms',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              ),
            ),
            Text(
              '•',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'Privacy',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label, this.icon});

  final String value;
  final String label;
  final IconData? icon;

  static const _gold = Color(0xFFFFB629);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: _gold, size: 18),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
