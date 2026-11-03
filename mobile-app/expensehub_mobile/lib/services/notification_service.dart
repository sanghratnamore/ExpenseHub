import 'dart:convert';
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static VoidCallback? onNotificationReceived;

  Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings();

    await _localNotifications.initialize(
      settings: InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  Future<void> saveDeviceToken({
    required String token,
    required String jwtToken,
  }) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8080/api/notifications/device-token'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
      body: jsonEncode({
        'deviceToken': token,
        'platform': 'android',
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception(
        'Could not save device token. '
        'Status: ${response.statusCode}, '
        'Body: ${response.body}',
      );
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await _showForegroundNotification(message);

    final callback = onNotificationReceived;

    if (callback != null) {
      callback();
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;

    if (notification == null) return;

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'expensehub_group_channel',
          'Group activity',
          channelDescription:
              'Updates about group expenses and settlements',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}