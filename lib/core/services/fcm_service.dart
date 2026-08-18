import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await FCMService._showLocalNotification(message);
}

class FCMService {
  FCMService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Local notifications not supported on web
    if (!kIsWeb) {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      await _localNotifications.initialize(initSettings);

      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
    }

    FirebaseMessaging.onMessage.listen((message) {
      if (!kIsWeb) _showLocalNotification(message);
    });

    // subscribeToTopic is not supported on web
    if (!kIsWeb) {
      await _messaging.subscribeToTopic('all_users');
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'edutech_smk_channel',
      'EduTech SMK',
      channelDescription: 'EduTech SMK Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'EduTech SMK',
      message.notification?.body ?? '',
      details,
    );
  }

  static const String _vapidKey =
      'BOY4TBXGWNh4UNikrGOWE7hU5iYaK8qbt0YlerR-VJRVOEKKaFXXxe8MuCEsvDK4fa8sGKl9RWE6SnpJ5AAYtPY';

  static Future<String?> getToken() async {
    return _messaging.getToken(vapidKey: kIsWeb ? _vapidKey : null);
  }

  static Future<void> subscribeToTopic(String topic) async {
    if (!kIsWeb) await _messaging.subscribeToTopic(topic);
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    if (!kIsWeb) await _messaging.unsubscribeFromTopic(topic);
  }
}
