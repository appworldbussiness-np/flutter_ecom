import 'package:ecom_/providers/notification_provider.dart';
import 'package:ecom_/services/local_notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  static bool _initialized = false;

  static Future<void> init(NotificationProvider provider) async {
    if (_initialized) return;
    _initialized = true;

    final messaging = FirebaseMessaging.instance;

    // ✅ REQUEST PERMISSION (iOS)
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // ✅ SHOW NOTIFICATION IN FOREGROUND (iOS fix)
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 🔔 FOREGROUND LISTENER
    FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? "No Title";
      final body = message.notification?.body ?? "No Body";

      LocalNotificationService.show(title: title, body: body);

      provider.addNotification(
        title,
        body,
        type: message.data['type'] ?? "general",
      );
    });

    // 🔔 CLICK LISTENER
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final title = message.notification?.title ?? "No Title";
      final body = message.notification?.body ?? "No Body";

      provider.addNotification(
        title,
        body,
        type: message.data['type'] ?? "general",
      );
    });
  }
}
