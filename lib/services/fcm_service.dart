import 'package:ecom_/providers/notification_provider.dart';
import 'package:ecom_/services/local_notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  static bool _initialized = false; // ✅ prevent double init

  static void init(NotificationProvider provider) {
    if (_initialized) return; // 🚫 avoid duplicate listeners
    _initialized = true;

    FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? "No Title";
      final body = message.notification?.body ?? "No Body";

      print("📩 FCM RECEIVED: $title");

      LocalNotificationService.show(title: title, body: body);

      provider.addNotification(
        title,
        body,
        type: message.data['type'] ?? "general",
      );
    });

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
