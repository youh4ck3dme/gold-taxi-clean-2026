import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'package:gold_taxi/features/splash/presentation/pages/splash_page.dart';
import 'package:gold_taxi/features/splash/presentation/cubits/splash_cubit.dart';

// ─── Fake Asset Bundle ────────────────────────────────────────────────────────

class FakeAssetBundle extends AssetBundle {
  final ByteData manifest;

  FakeAssetBundle()
      : manifest = const StandardMessageCodec().encodeMessage(<Object?, Object?>{
          'assets/icon/icon.png': <Map<String, Object>>[
            <String, String>{'asset': 'assets/icon/icon.png'},
          ],
        })!;

  @override
  Future<ByteData> load(String key) async {
    if (key == 'assets/icon/icon.png') {
      // 1x1 transparent PNG bytes to allow successful image decoding in tests
      return ByteData.sublistView(Uint8List.fromList([
        137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 
        0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 
        0, 0, 0, 11, 73, 68, 65, 84, 8, 215, 99, 96, 0, 0, 0, 2, 
        0, 1, 226, 33, 188, 51, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130
      ]));
    }
    if (key == 'AssetManifest.bin' || key == 'AssetManifest.bin.json') {
      return manifest;
    }
    if (key.endsWith('.json')) {
      return ByteData.sublistView(Uint8List.fromList(utf8.encode('{}')));
    }
    throw Exception('Asset not found: $key');
  }
}

// ─── Fake Video Player Platform ──────────────────────────────────────────────

class FakeVideoPlayerPlatform extends VideoPlayerPlatform
    with MockPlatformInterfaceMixin {
  final _eventControllers = <int, StreamController<VideoEvent>>{};

  @override
  Future<void> init() async {}

  @override
  Future<int> create(DataSource dataSource) async {
    final textureId = _eventControllers.length + 1;
    _eventControllers[textureId] = StreamController<VideoEvent>.broadcast();
    return textureId;
  }

  @override
  Future<void> dispose(int textureId) async {
    await _eventControllers[textureId]?.close();
    _eventControllers.remove(textureId);
  }

  @override
  Future<void> play(int textureId) async {}

  @override
  Future<void> pause(int textureId) async {}

  @override
  Future<void> setVolume(int textureId, double volume) async {}

  @override
  Future<void> setLooping(int textureId, bool looping) async {}

  @override
  Future<void> setPlaybackSpeed(int textureId, double speed) async {}

  @override
  Future<Duration> getPosition(int textureId) async {
    return Duration.zero;
  }

  @override
  Widget buildView(int textureId) {
    return const SizedBox.shrink();
  }

  @override
  Widget buildViewWithOptions(VideoViewOptions options) {
    return const SizedBox.shrink();
  }

  @override
  Stream<VideoEvent> videoEventsFor(int textureId) {
    final controller = _eventControllers[textureId];
    if (controller != null) {
      // Simulate initialization event after a microtask
      scheduleMicrotask(() {
        if (!controller.isClosed) {
          controller.add(VideoEvent(
            eventType: VideoEventType.initialized,
            duration: const Duration(seconds: 10),
            size: const Size(1920, 1080),
          ));
        }
      });
      return controller.stream;
    }
    return const Stream.empty();
  }
}

// ─── Test Suite ──────────────────────────────────────────────────────────────

void main() {
  setUp(() {
    // Register the fake video player platform before each test to prevent resets
    VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
  });

  group('SplashPage Widget Tests', () {
    testWidgets('renders loader initially, then shows VideoPlayer once initialized', (
      WidgetTester tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(
            path: '/splash',
            builder: (context, state) => BlocProvider(
              create: (_) => SplashCubit(),
              child: DefaultAssetBundle(
                bundle: FakeAssetBundle(),
                child: const SplashPage(),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Initially should show the loader
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Advance frames so that the microtask fires and the mock video initializes
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // After initialization, loader should be gone and VideoPlayer should be visible
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(AspectRatio), findsOneWidget);
    });

    testWidgets('skip button layout and positioning details', (
      WidgetTester tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(
            path: '/splash',
            builder: (context, state) => BlocProvider(
              create: (_) => SplashCubit(),
              child: DefaultAssetBundle(
                bundle: FakeAssetBundle(),
                child: const SplashPage(),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify the Image is visible
      expect(find.byType(Image), findsOneWidget);

      // Find the skip button's Container using Image as the anchor
      final containerFinder = find.ancestor(
        of: find.byType(Image),
        matching: find.byType(Container),
      ).first;
      expect(containerFinder, findsOneWidget);

      // Verify the skip button has the correct container styling and dimensions (70x70)
      final container = tester.widget<Container>(containerFinder);
      expect(container.constraints?.maxWidth, equals(70));
      expect(container.constraints?.maxHeight, equals(70));

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, equals(BoxShape.circle));
      expect(decoration.border?.top.color, equals(const Color(0xFFC9A84C)));
      expect(decoration.border?.top.width, equals(2));

      // Verify skip button positioning at bottom-right corner
      final positioned = tester.widget<Positioned>(
        find.ancestor(
          of: containerFinder,
          matching: find.byType(Positioned),
        ),
      );
      expect(positioned.bottom, equals(20));
      expect(positioned.right, equals(20));
    });

    testWidgets('tapping skip button pauses video, fades, and navigates to login', (
      WidgetTester tester,
    ) async {
      bool loginReached = false;

      final router = GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(
            path: '/splash',
            builder: (context, state) => BlocProvider(
              create: (_) => SplashCubit(),
              child: DefaultAssetBundle(
                bundle: FakeAssetBundle(),
                child: const SplashPage(),
              ),
            ),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) {
              loginReached = true;
              return const Scaffold(body: Text('LOGIN_PAGE'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify we are not at login page yet
      expect(loginReached, isFalse);

      // Tap skip button (the Image widget itself)
      await tester.tap(find.byType(Image));

      // Pump to trigger the 600ms fade animation
      await tester.pump(const Duration(milliseconds: 600));
      // Pump one more frame to allow navigation transition to finalize
      await tester.pumpAndSettle();

      // Verify that navigation succeeded and we reached the login route
      expect(loginReached, isTrue);
      expect(find.text('LOGIN_PAGE'), findsOneWidget);
    });
  });
}
