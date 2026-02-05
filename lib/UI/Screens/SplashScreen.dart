import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

import 'HomeScreen.dart';

void main() {
  runApp(const MaterialApp(
    home: SplashScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA42FC1), // Your purple background
      body: Stack(
        children: [
          // 1. Background Stars
          const FullScreenStars(starCount: 50),

          // 2. Middle Layer: Robot Image
          Center(
            child: Image.asset(
              'Assets/Images/robotimagetosplash.png',
              height: 250,
              width: 250,
            ),
          ),

          // 3. Footer Section (Fixed Nesting)
          const Positioned(
            bottom: 50, // Adjusted to make room for the legal text
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      "n%hsgd",
                      style: TextStyle(
                        fontSize: 55,
                        color: Colors.white,
                        fontFamily: "Sinhasithija2012",
                      ),
                    ),
                    Positioned(
                      top: 45, // Moved up slightly to look balanced
                      child: Row(
                        children: [
                          SizedBox(width: 20),
                          Text(
                            "Braita",
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: "InterMedium",
                              color: Color(0xFFFFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 4. Rights Reserved Text
          const Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Text(
              "All rights reserved by KITAAS Solutions © 2026",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontFamily: "InterRegular",
                color: Color(0xFFFFFFFF),
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
                    errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.star,
                        color: Colors.white.withOpacity(0.5),
                        size: size),
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