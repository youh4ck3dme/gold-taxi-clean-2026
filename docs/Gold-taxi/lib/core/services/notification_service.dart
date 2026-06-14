import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logger/logger.dart';
import 'package:gold_taxi/routes/app_router.dart';

class NotificationService {
  final Logger _logger = Logger();

  FirebaseMessaging? get _fcm {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseMessaging.instance;
      }
    } catch (_) {}
    return null;
  }

  /// Initialize Firebase Messaging and listeners
  Future<void> initialize() async {
    final fcm = _fcm;
    if (fcm == null) {
      _logger.w('🔔 Firebase Messaging is not initialized (Firebase.initializeApp failed or is not configured).');
      return;
    }

    // 1. Request permissions (especially for iOS and Android 13+)
    final settings = await fcm.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      _logger.i('🔔 User granted notification permission');
    } else {
      _logger.w('🔔 User declined or has not accepted notification permission');
    }

    // 2. Fetch device token
    try {
      final token = await fcm.getToken();
      _logger.i('🔔 FCM Token: $token');
      // Here you would typically send this token to your WordPress backend CPT / User Meta
    } catch (e) {
      _logger.e('🔔 Error getting FCM token: $e');
    }

    // 3. Listen to messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _logger.i('🔔 Message received in foreground: ${message.notification?.title}');
      // You can show a local alert or custom notification card here
    });

    // 4. Handle notification click when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _logger.i('🔔 Notification clicked (app in background)');
      _handleMessageRoute(message);
    });

    // 5. Check if the app was opened from a terminated state via a notification
    final initialMessage = await fcm.getInitialMessage();
    if (initialMessage != null) {
      _logger.i('🔔 Notification clicked (app was terminated)');
      _handleMessageRoute(initialMessage);
    }
  }

  void _handleMessageRoute(RemoteMessage message) {
    final route = message.data['route'] as String?;
    if (route != null && route.isNotEmpty) {
      appRouter.go(route);
    }
  }
}
