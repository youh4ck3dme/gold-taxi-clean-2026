import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/service_locator.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../auth/presentation/cubits/auth_state.dart';
import '../../../profile/presentation/bloc/profile_cubit.dart';

class SplashPage extends StatefulWidget {
  final AppConfig config;
  final VoidCallback onInitComplete;

  const SplashPage({
    super.key,
    required this.config,
    required this.onInitComplete,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _isAppInitialized = false;
  bool _isSkipping = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _skipButtonController;
  late AnimationController _pulseController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _skipButtonFadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Fade overlay: 0.0 → 1.0 (dark overlay)
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Skip button fade-in (appears after video loads)
    _skipButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _skipButtonFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _skipButtonController, curve: Curves.easeOut),
    );

    // Pulse animation for the skip button glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    _initializeVideo();
    _initializeApp();
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.asset('assets/video/splash.mp4');
    try {
      await _videoController.initialize();
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        await _videoController.setVolume(0.0);
        await _videoController.setLooping(true); // Loop indefinitely
        await _videoController.play();

        // Show skip button after a brief delay so user watches the intro
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            _skipButtonController.forward();
          }
        });
      }
    } catch (e) {
      debugPrint('🔴 Failed to initialize video: $e');
      // If video fails, show skip button immediately
      if (mounted) {
        _skipButtonController.forward();
      }
    }
  }

  Future<void> _initializeApp() async {
    try {
      // 1. Hive local storage
      await Hive.initFlutter();

      // 2. Setup service locator
      final backendMode = widget.config.enableMockMode
          ? BackendMode.mock
          : BackendMode.supabase;
      await setupServiceLocator(mode: backendMode);
      debugPrint('🏗️ Service Locator initialized in $backendMode mode.');

      // 3. Setup Supabase client
      try {
        await Supabase.initialize(
          url: widget.config.supabaseUrl,
          publishableKey: widget.config.supabaseAnonKey,
        );
        debugPrint('⚡ Supabase Client initialized successfully.');
      } catch (e) {
        debugPrint('🔴 Supabase initialization failed: $e');
      }

      // 4. Check auth status (AuthCubit)
      final authCubit = getIt<AuthCubit>();
      await authCubit.checkAuthStatus();

      // 5. If authenticated, load profile
      if (authCubit.state is Authenticated) {
        try {
          await getIt<ProfileCubit>().fetchProfile();
        } catch (e) {
          debugPrint('🔴 Profile load failed during splash: $e');
        }
      }
    } catch (e, stack) {
      debugPrint('🔴 Background initialization failed: $e');
      debugPrint(stack.toString());
    }

    if (mounted) {
      setState(() {
        _isAppInitialized = true;
      });
    }
  }

  /// Called when user taps the skip button
  Future<void> _onSkipPressed() async {
    if (_isSkipping) return;
    setState(() => _isSkipping = true);

    // Stop the video
    try {
      await _videoController.pause();
    } catch (_) {}

    // Play fade-to-dark overlay
    await _fadeController.forward().orCancel.catchError((_) {});

    // Wait for app init if not done yet
    if (!_isAppInitialized) {
      await _waitForInit();
    }

    // Launch the main app
    if (mounted) {
      widget.onInitComplete();
    }
  }

  Future<void> _waitForInit() async {
    while (!_isAppInitialized && mounted) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _fadeController.dispose();
    _skipButtonController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          // Layer 1: Full-screen video
          _buildVideoLayer(),

          // Layer 2: Fade-to-dark overlay (animated)
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return IgnorePointer(
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Container(color: const Color(0xFF050505)),
                ),
              );
            },
          ),

          // Layer 3: Skip button (bottom-right)
          if (!_isSkipping) _buildSkipButton(),

          // Layer 4: Loading indicator while waiting for init after skip
          if (_isSkipping && !_isAppInitialized)
            Center(
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFC59B47),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoLayer() {
    if (!_isVideoInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC59B47)),
        ),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController.value.size.width,
          height: _videoController.value.size.height,
          child: VideoPlayer(_videoController),
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 32,
      right: 24,
      child: FadeTransition(
        opacity: _skipButtonFadeAnimation,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return _SkipIconButton(
              pulseValue: _pulseAnimation.value,
              onPressed: _onSkipPressed,
            );
          },
        ),
      ),
    );
  }
}

/// Stateful skip button with press animation and app icon
class _SkipIconButton extends StatefulWidget {
  final double pulseValue;
  final VoidCallback onPressed;

  const _SkipIconButton({required this.pulseValue, required this.onPressed});

  @override
  State<_SkipIconButton> createState() => _SkipIconButtonState();
}

class _SkipIconButtonState extends State<_SkipIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Skip to login',
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.90 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                // Outer gold glow (pulsing)
                BoxShadow(
                  color: const Color(
                    0xFFC59B47,
                  ).withValues(alpha: 0.35 * widget.pulseValue),
                  blurRadius: 20 * widget.pulseValue,
                  spreadRadius: 2 * widget.pulseValue,
                ),
                // Subtle dark shadow for depth
                const BoxShadow(
                  color: Colors.black54,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFC59B47).withValues(alpha: 0.7),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/icon/icon.png',
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
