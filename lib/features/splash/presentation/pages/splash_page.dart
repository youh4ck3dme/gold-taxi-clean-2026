import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubits/splash_cubit.dart';
import '../cubits/splash_state.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.asset('assets/videos/splash.mp4')
      ..initialize().then((_) {
        setState(() {});
        _videoController.play();
        _videoController.setLooping(false);

        // Start app initialization (3.2 seconds)
        context.read<SplashCubit>().initializeApp();
      }).catchError((error) {
        debugPrint('❌ Video Error: $error');
        // If video fails, skip splash
        context.read<SplashCubit>().initializeApp();
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashCubit, SplashState>(
      listener: (context, state) {
        if (state is SplashCompleted) {
          // Navigate to home (GoRouter redirect will handle auth)
          context.go('/');
        } else if (state is SplashError) {
          debugPrint('🔴 Splash Error: ${state.message}');
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: _videoController.value.isInitialized
              ? AspectRatio(
                  aspectRatio: _videoController.value.aspectRatio,
                  child: VideoPlayer(_videoController),
                )
              : const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC9A84C)),
                ),
        ),
      ),
    );
  }
}
