import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

// Update these imports to match your project folder structure
import '../../Ads/app_open_ad_manager.dart';

import 'HomeScreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AppOpenAdManager _adManager = AppOpenAdManager();
  bool _hasNavigated = false; // Ensures we only navigate once

  @override
  void initState() {
    super.initState();

    // 1. Start loading the ad.
    // This callback fires as soon as Google says "Ready" or "Failed".
    _adManager.loadAd(onAdLoaded: () {
      _navigateToNext();
    });

    // 2. Safety Timer: If the ad/internet is slow, don't wait forever.
    Timer(const Duration(seconds: 10), () {
      _navigateToNext();
    });
  }

  void _navigateToNext() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    // Show the ad if it's there; if not, showAdIfAvailable will just run the callback.
    _adManager.showAdIfAvailable(() {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA42FC1), // Braita Purple
      body: Stack(
        children: [
          // 1. Animated-style Star Background
          const FullScreenStars(starCount: 50),

          // 2. Center Content: Robot + Loader
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'Assets/Images/robotimagetosplash.png',
                  height: 250,
                  width: 250,
                ),
                const SizedBox(height: 40),
                // Circular loading indicator
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Preparing Braita...",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,

                  ),
                ),
              ],
            ),
          ),

          // 3. Footer Branding
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'Assets/Images/textsplash.png',
                height: 54,
              ),
            ),
          ),

          // 4. Copyright Info
          const Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Text(
              "All rights reserved by KITAAS Solutions © 2026",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FullScreenStars extends StatelessWidget {
  final int starCount;
  const FullScreenStars({super.key, required this.starCount});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final random = math.Random();
        int columns = 6;
        int rows = (starCount / columns).ceil();

        double cellWidth = constraints.maxWidth / columns;
        double cellHeight = constraints.maxHeight / rows;

        List<Widget> stars = [];

        for (int i = 0; i < rows; i++) {
          for (int j = 0; j < columns; j++) {
            double top = (i * cellHeight) + random.nextDouble() * (cellHeight - 50);
            double left = (j * cellWidth) + random.nextDouble() * (cellWidth - 50);

            top = top.clamp(0, constraints.maxHeight - 50);
            left = left.clamp(0, constraints.maxWidth - 50);

            double size = random.nextDouble() * 40 + 10;
            double opacity = random.nextDouble() * 0.4 + 0.2;

            stars.add(
              Positioned(
                top: top,
                left: left,
                child: Opacity(
                  opacity: opacity,
                  child: Image.asset(
                    'Assets/Images/star2.png',
                    height: size,
                    width: size,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.star, color: Colors.white.withOpacity(0.5), size: size),
                  ),
                ),
              ),
            );
          }
        }
        return Stack(children: stars);
      },
    );
  }
}