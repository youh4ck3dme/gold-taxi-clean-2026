import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({
    super.key,
    this.onBookRide,
    this.onDriverMode,
    this.onLogin,
  });

  final VoidCallback? onBookRide;
  final VoidCallback? onDriverMode;
  final VoidCallback? onLogin;

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

  void _fallbackNavigate(String routeName) {
    context.go(routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _deepBlack,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            children: [
              _AnimatedLuxuryBackground(progress: _controller.value),
              const _GoldNoiseOverlay(),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 820;
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 56 : 22,
                        vertical: isWide ? 34 : 18,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1180),
                          child: isWide
                              ? Row(
                                  children: [
                                    const Expanded(
                                      flex: 6,
                                      child: _HeroCopy(),
                                    ),
                                    const SizedBox(width: 44),
                                    Expanded(
                                      flex: 5,
                                      child: _WelcomeActionCard(
                                        onBookRide: widget.onBookRide ??
                                            () => _fallbackNavigate('/'),
                                        onDriverMode: widget.onDriverMode ??
                                            () => _fallbackNavigate('/driver'),
                                        onLogin: widget.onLogin ??
                                            () => _fallbackNavigate('/login'),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    const Expanded(
                                      child: SingleChildScrollView(
                                        physics: BouncingScrollPhysics(),
                                        child: _HeroCopy(),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    _WelcomeActionCard(
                                      onBookRide: widget.onBookRide ??
                                          () => _fallbackNavigate('/'),
                                      onDriverMode: widget.onDriverMode ??
                                          () => _fallbackNavigate('/driver'),
                                      onLogin: widget.onLogin ??
                                          () => _fallbackNavigate('/login'),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

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
              colors: [
                Color(0xFF382300),
                Color(0xFF111827),
                Color(0xFF050505),
              ],
            ),
          ),
        ),
        Positioned(
          top: -120 + math.sin(angle) * 18,
          right: -90 + math.cos(angle) * 18,
          child: const _GlowOrb(
            size: 280,
            color: Color(0x66FFB629),
          ),
        ),
        Positioned(
          bottom: -160 + math.cos(angle) * 14,
          left: -110 + math.sin(angle) * 14,
          child: const _GlowOrb(
            size: 340,
            color: Color(0x334B5563),
          ),
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
  const _GlowOrb({
    required this.size,
    required this.color,
  });
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
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
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
        child: CustomPaint(
          size: Size.infinite,
          painter: _NoisePainter(),
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy();
  static const _gold = Color(0xFFFFB629);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 420;

    return Padding(
      padding: EdgeInsets.only(top: isCompact ? 24 : 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BrandMark(),
          const SizedBox(height: 34),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, color: _gold, size: 18),
                SizedBox(width: 8),
                Text(
                  'Premium taxi & executive rides',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text(
            'Gold Taxi',
            style: theme.textTheme.displayLarge?.copyWith(
              color: Colors.white,
              fontSize: isCompact ? 56 : 82,
              height: 0.92,
              fontWeight: FontWeight.w900,
              letterSpacing: -3.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Keď chceš prísť načas,\nnie len dramaticky.',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: isCompact ? 28 : 42,
              height: 1.05,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.1,
            ),
          ),
          const SizedBox(height: 22),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(
              'Objednaj si prémiovú jazdu, sleduj vodiča na mape a nechaj chaos verejnej dopravy tým, ktorí si myslia, že meškanie je životný štýl.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color(0xFFB8BEC9),
                fontSize: 17,
                height: 1.55,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FeaturePill(icon: Icons.flash_on_rounded, label: 'Rýchle vyžiadanie'),
              _FeaturePill(icon: Icons.map_rounded, label: 'Live tracking'),
              _FeaturePill(icon: Icons.shield_rounded, label: 'Bezpečné jazdy'),
              _FeaturePill(icon: Icons.workspace_premium_rounded, label: 'Premium vodiči'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();
  static const _gold = Color(0xFFFFB629);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 54,
          width: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFD166),
                Color(0xFFFFB629),
                Color(0xFF9B5C00),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: _gold.withValues(alpha: 0.32),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_taxi_rounded,
            color: Colors.black,
            size: 29,
          ),
        ),
        const SizedBox(width: 14),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gold Taxi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Košice premium mobility',
              style: TextStyle(
                color: Color(0xFFB8BEC9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({
    required this.icon,
    required this.label,
  });
  final IconData icon;
  final String label;
  static const _gold = Color(0xFFFFB629);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.075),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _gold, size: 17),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeActionCard extends StatelessWidget {
  const _WelcomeActionCard({
    required this.onBookRide,
    required this.onDriverMode,
    required this.onLogin,
  });
  final VoidCallback onBookRide;
  final VoidCallback onDriverMode;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.095),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 36,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _MiniMapPreview(),
              const SizedBox(height: 22),
              _PrimaryGoldButton(
                label: 'Objednať jazdu',
                icon: Icons.near_me_rounded,
                onPressed: onBookRide,
              ),
              const SizedBox(height: 12),
              _SecondaryButton(
                label: 'Som vodič',
                icon: Icons.drive_eta_rounded,
                onPressed: onDriverMode,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onLogin,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withValues(alpha: 0.84),
                ),
                child: const Text(
                  'Už mám účet',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryGoldButton extends StatelessWidget {
  const _PrimaryGoldButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  static const _gold = Color(0xFFFFB629);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.black),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: _gold,
          foregroundColor: Colors.black,
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: -0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.18),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white.withValues(alpha: 0.06),
        ),
      ),
    );
  }
}

class _MiniMapPreview extends StatelessWidget {
  const _MiniMapPreview();
  static const _gold = Color(0xFFFFB629);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.18,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: const Color(0xFF0E1624),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _MiniMapPainter(),
              ),
            ),
            Positioned(
              left: 22,
              top: 22,
              child: _MapBadge(
                icon: Icons.location_on_rounded,
                label: 'Košice centrum',
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
            const Positioned(
              right: 24,
              bottom: 28,
              child: _DriverAvatar(),
            ),
            Positioned(
              left: 24,
              bottom: 26,
              right: 94,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.48),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Najbližší vodič',
                      style: TextStyle(
                        color: Color(0xFFB8BEC9),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '2 min · Premium',
                      style: TextStyle(
                        color: _gold,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapBadge extends StatelessWidget {
  const _MapBadge({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;
  static const _gold = Color(0xFFFFB629);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _gold, size: 17),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverAvatar extends StatelessWidget {
  const _DriverAvatar();
  static const _gold = Color(0xFFFFB629);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _gold,
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.local_taxi_rounded,
        color: Colors.black,
        size: 30,
      ),
    );
  }
}

class _MiniMapPainter extends CustomPainter {
  static const _gold = Color(0xFFFFB629);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.055)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 34) {
      canvas.drawLine(Offset(x, 0), Offset(x + 52, size.height), gridPaint);
    }
    for (var y = 0.0; y < size.height; y += 38) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 26), gridPaint);
    }
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final road = Path()
      ..moveTo(size.width * 0.08, size.height * 0.72)
      ..cubicTo(
        size.width * 0.26,
        size.height * 0.52,
        size.width * 0.43,
        size.height * 0.80,
        size.width * 0.62,
        size.height * 0.48,
      )
      ..cubicTo(
        size.width * 0.75,
        size.height * 0.26,
        size.width * 0.86,
        size.height * 0.38,
        size.width * 0.94,
        size.height * 0.20,
      );
    canvas.drawPath(road, roadPaint);
    final goldRoadPaint = Paint()
      ..color = _gold.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(road, goldRoadPaint);
    final pickupPaint = Paint()..color = Colors.white;
    final destinationPaint = Paint()..color = _gold;
    canvas.drawCircle(
      Offset(size.width * 0.16, size.height * 0.70),
      7,
      pickupPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.79, size.height * 0.34),
      8,
      destinationPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
