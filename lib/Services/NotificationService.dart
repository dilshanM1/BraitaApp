import 'package:firebase_database/firebase_database.dart'; // Add this for Firebase logic
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // 1. Change this to a late variable or initialize it inside a method
  static late DatabaseReference _dbRef;

  static Future<void> init() async {
    tz.initializeTimeZones();
    var srilanka = tz.getLocation('Asia/Colombo');
    tz.setLocalLocation(srilanka);

    const androidSettings = AndroidInitializationSettings('notification_icon');
    const iosSettings = DarwinInitializationSettings(requestAlertPermission: true);

    await _notificationsPlugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    await requestPermissions();

    // 2. Initialize the DB reference here AFTER we know Firebase is ready
    _dbRef = FirebaseDatabase.instance.ref("Notifications");

    listenToDatabaseNotifications();
  }

// ... rest of your methods


  // --- NEW: DATABASE DRIVEN NOTIFICATION ---
  static void listenToDatabaseNotifications() {
    _dbRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        // Extract Title (Topic) and Message from your Firebase structure
        String title = data['Topic'] ?? "Braita Update";
        String message = data['Message'] ?? "Check out the latest quizzes!";

        // Show the notification immediately when database changes
        showInstantDatabaseNotification(title, message);
      }
    });
  }

  static Future<void> showInstantDatabaseNotification(String title, String message) async {
    const androidDetails = AndroidNotificationDetails(
      'db_alerts_channel_v2',
      'Database Alerts',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF9C27B0),
      playSound: true,
    );

    await _notificationsPlugin.show(
      999, // Unique ID for DB notifications
      title,
      message,
      const NotificationDetails(android: androidDetails),
    );
  }
// Update your requestPermissions method
  static Future<void> requestPermissions() async {
    // 1. Just request normally. Android will show the popup if it hasn't before.
    await Permission.notification.request();

    // 2. Check for Exact Alarm
    var status = await Permission.scheduleExactAlarm.status;

    // ONLY open settings if they have already denied it once or permanently.
    // If it's 'isGranted', this block is skipped, and the loop stops!
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    } else if (status.isDenied) {
      // Try requesting one more time before forcing settings
      await Permission.scheduleExactAlarm.request();
    }
  }

// Update your scheduling methods to be safer
  static Future<void> scheduleDailySevenPM() async {
    // Check permission first to avoid crash on Android 14
    final bool canScheduleExact = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!
        .canScheduleExactNotifications() ?? false;

    if (!canScheduleExact) {
      debugPrint("Cannot schedule exact alarm: Permission missing");
      return;
    }

    await _notificationsPlugin.zonedSchedule(
      101,
      "Braita Quiz Time! 🧠",
      "Reach the Hero Ranking! Complete your 20 quizzes today.",
      _nextInstanceOfSevenPM(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'braita_daily_channel',
          'Daily Reminders',
          importance: Importance.max,
          priority: Priority.high,
          color: Color(0xFF9C27B0),
        ),
      ),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      // Use this mode for high-reliability reminders
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _nextInstanceOfSevenPM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 19, 0);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}

//correct before add 7 pm to firebase update 03.02.2026