import 'package:braita_new/UI/Screens/SettingsScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for SystemNavigator.pop()
import '../Screens/HerosScreen.dart';
import '../Screens/QuizScreen.dart';
import '../Screens/HomeScreen.dart';

class BottomNavigation extends StatefulWidget {
  final int currentIndex;
  const BottomNavigation({super.key, required this.currentIndex});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  DateTime? _lastPressedAt; // Track time for double-click exit

  void _onTap(int index, Widget screen) {
    if (widget.currentIndex == index) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) => screen,
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, anim, secAnim, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double itemWidth = (screenWidth - 20) / 4;

    return PopScope(
        canPop: false, // Prevent the default back behavior
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;

          // RULE 1: If not on Home tab, back button takes you to Home
          if (widget.currentIndex != 0) {
            _onTap(0, const HomeScreen());
            return;
          }

          // RULE 2: If already on Home tab, handle double-click to exit
          final now = DateTime.now();
          if (_lastPressedAt == null ||
              now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
            _lastPressedAt = now;

            // Notify the user
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Double click back button to exit from Braita 😒😑",
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Color(0xFFBA7873),
              ),
            );
            return;
          }

          // If second click is within 2 seconds, close the app
          SystemNavigator.pop();
        },
        child: SafeArea(
          top: false,
          bottom: true,
          child: Container(
            height: 55,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF9C27B0),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutQuart,
                  left: (widget.currentIndex * itemWidth) + 5,
                  top: 7,
                  child: Container(
                    width: itemWidth - 10,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // --- SLIDING BACKGROUND RECTANGLE ---
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutQuart, // Smooth sliding curve
                  left: (widget.currentIndex * itemWidth) +
                      5, // Offset based on index
                  top: 7,
                  child: Container(
                    width: itemWidth - 10,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, "Assets/Icon/home.png", "Home",
                        const HomeScreen(), itemWidth),
                    _buildNavItem(1, "Assets/Icon/quiz.png", "Quiz",
                        const QuizScreen(), itemWidth),
                    _buildNavItem(2, "Assets/Icon/heros2.png", "Hero's",
                        const HerosScreen(), itemWidth),
                    _buildNavItem(3, "Assets/Icon/settings.png", "Settings",
                        const SettingsScreen(), itemWidth),
                  ],
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildNavItem(
      int index, String iconPath, String label, Widget screen, double width) {
    bool isActive = widget.currentIndex == index;

    return GestureDetector(
      onTap: () => _onTap(index, screen),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        height: 55,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconPath,
              height: 24,
              width: 24,
              color: Colors.white,
            ),
            ClipRect(
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                alignment: Alignment.centerLeft,
                widthFactor: isActive ? 1.0 : 0.0,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
