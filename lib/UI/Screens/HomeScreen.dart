import 'package:braita_new/UI/Screens/AwardScreen.dart';
import 'package:braita_new/UI/Screens/QuizScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:braita_new/UI/Widgets/BottomNavigationBar.dart';
import 'package:braita_new/Services/DatabaseService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Ads/banner_ad_manager.dart';
import 'ExamResultsScreen.dart';
import 'GuideVideoScreen.dart';
import 'PastpapersScreen.dart';
import 'ProfileScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final DatabaseService _dbService = DatabaseService();
  String? _deviceId;
  bool _dialogShown = false;
  bool _showGuidePopup = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserContext();
    _checkUpdateStatus();
    _checkGuidePopup();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _checkGuidePopup() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int count = prefs.getInt('guide_show_count') ?? 0;
    if (count < 2) {
      setState(() => _showGuidePopup = true);
      await prefs.setInt('guide_show_count', count + 1);
    }
  }

  void _checkUpdateStatus() {
    const int currentAppVersion = 2;
    _dbRef.child('Updates').onValue.listen((event) {
      if (!mounted) return;
      final data = event.snapshot.value as Map?;
      if (data != null) {
        int status = data['Avalable'] ?? 0;
        int latestVersion = data['Version'] ?? 2;
        if (status == 1 && latestVersion > currentAppVersion && !_dialogShown) {
          setState(() => _dialogShown = true);
          _showUpdateDialog();
        }
      }
    });
  }

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
      bottomNavigationBar: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MyBannerAdWidget(),
          BottomNavigation(currentIndex: 0),
        ],
      ),
      body: _deviceId == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF9C27B0)))
          : StreamBuilder(
        stream: _dbRef.child('User').child(_deviceId!).onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          int correctCount = 0;
          int wrongCount = 0;
          int myTotalPoints = 0;

          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            Map userData = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
            correctCount = userData['TotalCorrectAnsweredQuizCount'] ?? 0;
            wrongCount = userData['TotalWrongAnsweredQuizCount'] ?? 0;
            myTotalPoints = userData['MyPoints'] ?? 0;
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
                          _buildHeader(context, myTotalPoints),
                          Positioned(
                            top: 330,
                            child: _buildFloatingStatsCard(context, correctCount, wrongCount),
                          ),
                          // Winners Popup with Click Navigation
                          Positioned(
                            top: 250,
                            right: 17,
                            child: ScaleTransition(
                              scale: _pulseAnimation,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const AwardScreen()),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      )
                                    ],
                                  ),
                                  child: Image.asset(
                                    'Assets/Images/winners_popup.png',
                                    width: 140,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
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

  // --- Helper Methods (Animated Points, Counters, Dialogs, etc.) ---

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

  Widget _buildAnimatedCounter(int targetValue, TextStyle style, {bool pad = false}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: targetValue.toDouble()),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutExpo,
      builder: (context, value, child) {
        String displayValue = value.toInt().toString();
        if (pad) displayValue = displayValue.padLeft(3, '0');
        return Text(displayValue, style: style);
      },
    );
  }

  Widget _buildAnimatedPointsCircle(int points) {
    return Container(
      width: 200, height: 200,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.2), width: 10)),
      child: Container(
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.7), width: 10)),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.4), width: 15)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAnimatedCounter(points, const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Color(0xFF9C27B0), height: 0.8), pad: true),
              const Text("My Points", style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingStatsCard(BuildContext context, int correct, int wrong) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.88,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatIndicator(correct, "Correct", Colors.green, isCorrect: true),
              const SizedBox(width: 20),
              _buildStatIndicator(wrong, "Wrong", Colors.red, isCorrect: false),
            ],
          ),
          const SizedBox(height: 20),
          const Text("Attempt more quizzes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF635E64))),
          const SizedBox(height: 10),
          const Text("Try more quizzes and earn more points by testing your knowledge across different topics.", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF635E64), height: 1.4)),
          const SizedBox(height: 20),
          _buildCardFooter(),
        ],
      ),
    );
  }

  Widget _buildStatIndicator(int value, String label, Color color, {required bool isCorrect}) {
    Widget counterCircle = CircleAvatar(radius: 22, backgroundColor: const Color(0xFF9C27B0), child: _buildAnimatedCounter(value, const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)));
    Widget labelText = Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15));
    return Row(children: isCorrect ? [counterCircle, const SizedBox(width: 10), labelText] : [labelText, const SizedBox(width: 10), counterCircle]);
  }

  Widget _buildTopActionBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Image.asset("Assets/Images/changelanguage.png", height: 28, width: 28, fit: BoxFit.contain),
          const SizedBox(width: 15),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GuideVideoScreen())),
                child: Image.asset("Assets/Images/help_icon.png", height: 35, width: 35, fit: BoxFit.contain),
              ),
              if (_showGuidePopup)
                Positioned(
                  top: 32,
                  child: Column(
                    children: [
                      CustomPaint(size: const Size(15, 10), painter: TrianglePainter()),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))]),
                        child: const Column(
                          children: [
                            Text("Click here to watch the guide", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                            Text("ඇප් එක පාවිච්චි කරන හැටි බලන්න", style: TextStyle(fontSize: 9, color: Colors.black54)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 15),
          Stack(
            alignment: Alignment.center,
            children: [
              const CircleAvatar(radius: 24, backgroundColor: Color(0xFFFFFFFF)),
              GestureDetector(
                onTap: () async {
                  final selectedImage = await Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                  if (selectedImage != null) {
                    await _dbRef.child('User').child(_deviceId!).update({'ProfileImage': selectedImage});
                  }
                },
                child: StreamBuilder(
                  stream: _dbRef.child('User').child(_deviceId!).onValue,
                  builder: (context, snapshot) {
                    String avatarPath = 'Assets/Images/avatar.png';
                    if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                      Map data = snapshot.data!.snapshot.value as Map;
                      String? dbImage = data['ProfileImage'];
                      if (dbImage != null && dbImage.isNotEmpty) avatarPath = dbImage;
                    }
                    return CircleAvatar(radius: 22, backgroundImage: AssetImage(avatarPath), backgroundColor: Colors.white24);
                  },
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildGridMenu(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMenuIcon(icon: Icons.assessment_rounded, label: "Exam Results", color: const Color(0xFFAFC109), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ExamResultsScreen()))),
          _buildMenuIcon(icon: Icons.description_rounded, label: "Past Papers", color: const Color(0xFF028A1F), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PastpapersScreen()))),
          _buildMenuIcon(icon: Icons.help_outline_rounded, label: "Quizzes", color: const Color(0xFF0977C1), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const QuizScreen()))),
        ],
      ),
    );
  }

  Widget _buildMenuIcon({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(width: 70, height: 70, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]), child: Icon(icon, color: Colors.white, size: 32)),
          const SizedBox(height: 12),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF635E64))),
        ],
      ),
    );
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15), decoration: const BoxDecoration(color: Color(0xFF9C27B0), borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))), child: const Text("Update Available", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
              const SizedBox(height: 20),
              Image.asset('Assets/Images/updatebota.png', height: 150),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(onPressed: () async {
                  const url = 'https://play.google.com/store/apps/details?id=com.xendrio.braita';
                  final Uri uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9C27B0), minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))), child: const Text("Update Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBDBDBD), minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))), child: const Text("Maybe Later", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(height: 15),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildFullStarPattern({required int rows, required int columns}) {
    List<Widget> stars = [];
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        stars.add(Positioned(top: (i * 90).toDouble() - 10, left: (j * 100).toDouble() - 10, child: Opacity(opacity: 0.3, child: Image.asset('Assets/Images/star2.png', width: (i + j) % 2 == 0 ? 85 : 55))));
      }
    }
    return stars;
  }

  Widget _buildCardFooter() {
    return Align(alignment: Alignment.bottomCenter, child: Container(height: 10, width: 100, decoration: const BoxDecoration(color: Color(0xFF9C27B0), borderRadius: BorderRadius.vertical(top: Radius.circular(10)))));
  }
}