import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'NotificationService.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    // 1. Request Permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Get the Token (Print this to your console so you can test)
    String? token = await _messaging.getToken();
    debugPrint("FCM Registration Token: $token");

    // 3. Handle messages when the app is OPEN (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        // Use your existing purple notification banner logic
        NotificationService.showInstantDatabaseNotification(
          message.notification!.title ?? "Braita",
          message.notification!.body ?? "",
        );
      }
    });

    // 4. Handle when the user clicks the notification to open the app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("Notification clicked: ${message.data}");
    });
  }
}

// 5. This MUST be outside the class and top-level
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // This allows the app to receive the message even if it's closed
  debugPrint("Handling background message: ${message.messageId}");
}