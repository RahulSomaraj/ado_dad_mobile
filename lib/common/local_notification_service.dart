import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Shows push notifications in the system shade (like Swiggy) when FCM messages arrive.
/// Foreground: we show a local notification. Background/Terminated: FCM shows if server sends notification payload.
class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Notifications',
    description: 'App notifications',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  static VoidCallback? _onNotificationTap;

  /// Initialize and request permissions. Call after Firebase.initializeApp().
  /// [onNotificationTap] is called when user taps the notification (e.g. navigate to /notifications).
  static Future<void> init({VoidCallback? onNotificationTap}) async {
    _onNotificationTap = onNotificationTap;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
    );
    const settings = InitializationSettings(
      android: android,
      iOS: ios,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onSelectNotification,
    );

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }

    if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  static void _onSelectNotification(NotificationResponse? response) {
    if (response != null && response.payload != 'ignored') {
      _onNotificationTap?.call();
    }
  }

  /// Show a notification in the system shade (status bar / pull-down).
  /// Use when FCM delivers a message while app is in foreground.
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const android = AndroidNotificationDetails(
      'high_importance_channel',
      'Notifications',
      channelDescription: 'App notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: android, iOS: ios);

    final id = DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
    await _plugin.show(id, title, body, details, payload: payload ?? '');
  }

  /// Call from FCM foreground handler: show in system shade and add to in-app list.
  static Future<void> showFromFcmMessage(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title'] ?? 'Notification';
    final body = message.notification?.body ?? message.data['body'] ?? '';
    await showNotification(title: title, body: body, payload: 'open_notifications');
  }
}
