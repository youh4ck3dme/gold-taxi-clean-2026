import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'widgets/hero_section.dart';
import 'widgets/features_card.dart';
import 'widgets/cta_buttons.dart';
import 'widgets/stats_section.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _deepBlack = Color(0xFF050505);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onGetStarted() {
    // Navigates to signup page
    context.go('/signup');
  }

  void _onSignIn() {
    // Navigates to login page
    context.go('/login');
  }

  void _onGoogleSignIn() {
    // Navigates to login page for now
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _deepBlack,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => _AnimatedLuxuryBackground(
              progress: _controller.value,
            ),
          ),
          const _GoldNoiseOverlay(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const HeroSection(),
                        const SizedBox(height: 48),
                        const KeyFeaturesSection(),
                        const SizedBox(height: 48),
                        CtaButtons(
                          onGetStarted: _onGetStarted,
                          onSignIn: _onSignIn,
                          onGoogleSignIn: _onGoogleSignIn,
                        ),
                        const SizedBox(height: 48),
                        const StatsSection(),
                        const SizedBox(height: 24),
                      ],
                    ),
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

// ============================================================================
// Background Elements Preserved
// ============================================================================

class _AnimatedLuxuryBackground extends StatelessWidget {
  const _AnimatedLuxuryBackground({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    final angle = progress * math.pi * 2;
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.7, -0.55),
              radius: 1.15,
              colors: [Color(0xFF382300), Color(0xFF111827), Color(0xFF050505)],
            ),
          ),
        ),
        Positioned(
          top: -120 + math.sin(angle) * 18,
          right: -90 + math.cos(angle) * 18,
          child: const _GlowOrb(size: 280, color: Color(0x66FFB629)),
        ),
        Positioned(
          bottom: -160 + math.cos(angle) * 14,
          left: -110 + math.sin(angle) * 14,
          child: const _GlowOrb(size: 340, color: Color(0x334B5563)),
        ),
        CustomPaint(
          painter: _RoadLinePainter(progress: progress),
          size: Size.infinite,
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 42, sigmaY: 42),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}

class _GoldNoiseOverlay extends StatelessWidget {
  const _GoldNoiseOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.045,
        child: CustomPaint(size: Size.infinite, painter: _NoisePainter()),
      ),
    );
  }
}

class _RoadLinePainter extends CustomPainter {
  const _RoadLinePainter({required this.progress});
  final double progress;
  static const _gold = Color(0xFFFFB629);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _gold.withValues(alpha: 0.09)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    final shift = progress * 60;
    for (var i = -2; i < 8; i++) {
      final y = size.height * 0.15 + i * 112 + shift;
      final path = Path()
        ..moveTo(-50, y)
        ..cubicTo(
          size.width * 0.22,
          y - 70,
          size.width * 0.64,
          y + 92,
          size.width + 60,
          y - 36,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoadLinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _NoisePainter extends CustomPainter {
  final math.Random _random = math.Random(42);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (var i = 0; i < 620; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.65, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
