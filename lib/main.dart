import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'Services/NotificationService.dart';
import 'firebase_options.dart';
import 'UI/Screens/SplashScreen.dart';
import 'Services/DatabaseService.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  // Transparent status bar setup
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));

  // 1. Initialize Firebase ONLY ONCE
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Initialize Notification Service
  // This already calls requestPermissions() inside init()
  await NotificationService.init();

  // 3. Setup other services
  final dbService = DatabaseService();
  await dbService.initializeUser();

  // 4. Schedule initial reminders
  // Wrap in a try-catch to be safe
  try {
    await NotificationService.scheduleDailySevenPM();
  } catch (e) {
    debugPrint("Initial scheduling failed: $e");
  }

  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
      },
    );
  }
}