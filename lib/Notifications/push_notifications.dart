import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotifications {
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permissions for iOS
    await messaging.requestPermission();

    // Initialize FlutterLocalNotificationsPlugin
    const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: androidInitializationSettings);

    await _localNotificationsPlugin.initialize(initializationSettings);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });
  }

  static Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'admin_channel', // Channel ID
      'Admin Notifications', // Channel Name
      channelDescription: 'Notifications for admin actions',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotificationsPlugin.show(
      message.hashCode, // Unique ID
      message.notification?.title,
      message.notification?.body,
      notificationDetails,
    );
  }
}
