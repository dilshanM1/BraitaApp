import 'package:braita_new/UI/Screens/QuizScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:braita_new/UI/Widgets/BottomNavigationBar.dart';
import 'package:braita_new/Services/DatabaseService.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ExamResultsScreen.dart';
import 'PastpapersScreen.dart';
import 'ProfileScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final DatabaseService _dbService = DatabaseService();
  String? _deviceId;
  bool _dialogShown = false;
  @override
  void initState() {
    super.initState();
    _loadUserContext();
    _checkUpdateStatus();
  }

  // --- NEW: Database Listener for Updates ---
  void _checkUpdateStatus() {
    // 1. Path  database structure
    _dbRef.child('Updates').onValue.listen((event) {
      if (!mounted) return;

      final data = event.snapshot.value as Map?;
      if (data != null) {
        int status = data['Avalable'] ?? 0;

        debugPrint("Update status received: $status");

        if (status == 1 && !_dialogShown) {
          setState(() => _dialogShown = true);
          _showUpdateDialog();
        }
      }
    });
  }

  // Fetch sanitized device ID
  Future<void> _loadUserContext() async {
    String? rawId = await _dbService.getDeviceId();
    if (rawId != null) {
      setState(() {
        _deviceId = rawId.replaceAll(RegExp(r'[.#$\[\]]'), '_');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const BottomNavigation(currentIndex: 0),
      body: _deviceId == null
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF9C27B0)))
          : StreamBuilder(
              stream: _dbRef.child('User').child(_deviceId!).onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                // Default placeholders to prevent the "Spinning Wheel" problem
                int correctCount = 0;
                int wrongCount = 0;

                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  Map userData = Map<dynamic, dynamic>.from(
                      snapshot.data!.snapshot.value as Map);
                  correctCount = userData['TotalCorrectAnsweredQuizCount'] ?? 0;
                  wrongCount = userData['TotalWrongAnsweredQuizCount'] ?? 0;
                }

                return Column(
                  children: [
                    const SizedBox(height: 35),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                // Header with Animated Points
                                _buildHeader(context, correctCount),
                                Positioned(
                                  top: 330,
                                  child: _buildFloatingStatsCard(
                                      context, correctCount, wrongCount),
                                ),
                              ],
                            ),
                            const SizedBox(height: 140),
                            _buildGridMenu(context),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  // --- Header with Animated Points Circle ---
  Widget _buildHeader(BuildContext context, int targetPoints) {
    return Container(
      margin: const EdgeInsets.all(10),
      height: 450,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF9C27B0),
        borderRadius: BorderRadius.all(Radius.circular(40)),
      ),
      child: Stack(
        children: [
          ..._buildFullStarPattern(rows: 6, columns: 4),
          Column(
            children: [
              _buildTopActionBar(context),
              const SizedBox(height: 5),
              _buildAnimatedPointsCircle(targetPoints),
            ],
          ),
        ],
      ),
    );
  }

  // --- NEW: Animated Counter Logic ---
  Widget _buildAnimatedCounter(int targetValue, TextStyle style,
      {bool pad = false}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: targetValue.toDouble()),
      duration: const Duration(milliseconds: 1500), // Completes in 1.5 seconds
      curve: Curves.easeOutExpo, // Starts fast, slows down at the end
      builder: (context, value, child) {
        String displayValue = value.toInt().toString();
        if (pad) displayValue = displayValue.padLeft(3, '0');
        return Text(displayValue, style: style);
      },
    );
  }

  Widget _buildAnimatedPointsCircle(int points) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 10),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.7), width: 10),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 15),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAnimatedCounter(
                points,
                const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF9C27B0),
                    height: 0.8),
                pad: true,
              ),
              const Text("My Points",
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  // --- Floating Stats Card with Animated Stats ---
  Widget _buildFloatingStatsCard(BuildContext context, int correct, int wrong) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.88,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatIndicator(correct, "Correct", Colors.green,
                  isCorrect: true),
              const SizedBox(width: 20),
              _buildStatIndicator(wrong, "Wrong", Colors.red, isCorrect: false),
            ],
          ),
          const SizedBox(height: 20),
          const Text("Attempt more quizzes",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF635E64))),
          const SizedBox(height: 10),
          const Text(
            "Try more quizzes and earn more points by testing\nyour knowledge across different topics.",
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 13, color: Color(0xFF635E64), height: 1.4),
          ),
          const SizedBox(height: 20),
          _buildCardFooter(),
        ],
      ),
    );
  }

  Widget _buildStatIndicator(int value, String label, Color color,
      {required bool isCorrect}) {
    Widget counterCircle = CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFF9C27B0),
      child: _buildAnimatedCounter(
        value,
        const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );

    Widget labelText = Text(label,
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15));

    return Row(
      children: isCorrect
          ? [counterCircle, const SizedBox(width: 10), labelText]
          : [labelText, const SizedBox(width: 10), counterCircle],
    );
  }

  // --- Other UI Helpers (Unchanged) ---

  Widget _buildTopActionBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Image.asset("Assets/Images/changelanguage.png",
              height: 30, width: 30),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const ProfileScreen())),
            child: const CircleAvatar(
              radius: 22,
              backgroundImage: AssetImage('Assets/Images/avatar.png'),
              backgroundColor: Colors.white24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridMenu(BuildContext context) {
    // Pass context here
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMenuIcon(
            icon: Icons.assessment_rounded,
            label: "Exam Results",
            color: const Color(0xFFAFC109),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ExamResultsScreen())),
          ),
          _buildMenuIcon(
            icon: Icons.description_rounded,
            label: "Past Papers",
            color: const Color(0xFF028A1F),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PastpapersScreen())),
          ),
          _buildMenuIcon(
            icon: Icons.help_outline_rounded,
            label: "Quizzes",
            color: const Color(0xFF0977C1),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const QuizScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuIcon({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap, // This is already here
  }) {
    return GestureDetector(
      onTap: onTap, // <--- ADD THIS LINE
      behavior: HitTestBehavior.opaque, // Ensures the whole area is clickable
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF635E64),
            ),
          ),
        ],
      ),
    );
  }

  // --- NEW: Custom Update Dialog (Matches image_270ad8.png) ---
  void _showUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must take action
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: const BoxDecoration(
                  color: Color(0xFF9C27B0),
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30)),
                ),
                child: const Text(
                  "Update Available",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              // Star robot mascot from your design
              Image.asset('Assets/Images/updatebota.png', height: 150),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: () async {
                    // Replace with your actual Play Store URL
                    const url =
                        'https://play.google.com/store/apps/details?id=com.xendrio.braita';
                    final Uri uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C27B0),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Text("Update Now",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBDBDBD),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Text("Maybe Later",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 15),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildFullStarPattern(
      {required int rows, required int columns}) {
    List<Widget> stars = [];
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        stars.add(Positioned(
            top: (i * 90).toDouble() - 10,
            left: (j * 100).toDouble() - 10,
            child: Opacity(
                opacity: 0.3,
                child: Image.asset('Assets/Images/star2.png',
                    width: (i + j) % 2 == 0 ? 85 : 55))));
      }
    }
    return stars;
  }

  Widget _buildCardFooter() {
    return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
            height: 10,
            width: 100,
            decoration: const BoxDecoration(
                color: Color(0xFF9C27B0),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(10)))));
  }
}

//correct full
