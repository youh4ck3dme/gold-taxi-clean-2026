import 'package:flutter/material.dart';

/// Grid of key features displayed on the welcome screen
class KeyFeaturesSection extends StatelessWidget {
  const KeyFeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: constraints.maxWidth > 600 ? 2.5 : 3.5,
          children: const [
            FeaturesCard(
              icon: Icons.flash_on_rounded,
              title: 'Easy Booking',
              subtitle: 'Request a ride in seconds',
            ),
            FeaturesCard(
              icon: Icons.account_balance_wallet_rounded,
              title: 'Transparent Pricing',
              subtitle: 'No hidden fees',
            ),
            FeaturesCard(
              icon: Icons.star_rounded,
              title: 'Rated Drivers',
              subtitle: 'Professional & vetted',
            ),
            FeaturesCard(
              icon: Icons.shield_rounded,
              title: 'Safe & Secure',
              subtitle: 'End-to-end encryption',
            ),
          ],
        );
      },
    );
  }
}

/// An individual feature card
class FeaturesCard extends StatelessWidget {
  const FeaturesCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  static const _gold = Color(0xFFFFB629);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _gold, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
