import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final notification = FlutterLocalNotificationsPlugin();
  final bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initNotification() async {
    if (_isInitialized) return;
    const initSettingsAndroid = AndroidInitializationSettings('');
    const initSeetingsIos = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSeetingsIos,
    );
    await notification.initialize(initSettings);
  }

  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        "channel_id",
        "notifications",
        channelDescription: "daily notification channel",
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
  }) async {
    return notification.show(id, title, body, const NotificationDetails());
  }
}
