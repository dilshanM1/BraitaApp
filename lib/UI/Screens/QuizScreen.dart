import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../Widgets/BottomNavigationBar.dart';
import 'package:braita_new/Services/DatabaseService.dart';
import 'ProfileScreen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with WidgetsBindingObserver {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final DatabaseService _dbService = DatabaseService();

  // Logic State
  List<Map<dynamic, dynamic>> _dailyQuizzes = [];
  int _currentQuizIndex = 0;
  String? _deviceId;
  String _today = DateFormat('dd-MM-yyyy').format(DateTime.now());

  // Timer & Answer State
  int _timerSeconds = 20;
  Timer? _timer;
  bool _isAnswered = false;
  int? _selectedAnswerIndex;

  // Real-time Progress Stats
  int _dbCorrect = 0;
  int _dbWrong = 0;
  int _remainingToday = 20;

  // Streak Tracking Logic
  int _streakCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserAndQuizzes();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed && !_isAnswered) {
      _startTimer();
    }
  }

  Future<void> _loadUserAndQuizzes() async {
    String? rawId = await _dbService.getDeviceId();
    if (rawId == null) return;

    setState(() {
      _deviceId = rawId.replaceAll(RegExp(r'[.#$\[\]]'), '_');
    });

    final userSnap = await _dbRef.child('User').child(_deviceId!).get();

    if (userSnap.exists) {
      Map data = userSnap.value as Map;
      int totalCompleted = data['TotalCompletedQuizCount'] ?? 0;

      var dailyNode = data['QuizProgress']?['QuizProgress']?[_today];
      if (dailyNode != null) {
        _remainingToday = dailyNode['RemainingQuizCount'] ?? 20;
        _dbCorrect = dailyNode['CorrectQuizCount'] ?? 0;
        _dbWrong = dailyNode['WrongQuizCount'] ?? 0;
      }

      if (_remainingToday <= 0) {
        setState(() => _dailyQuizzes = []);
        _showLimitReached();
        return;
      }

      String startKey = 'quiz${(totalCompleted + 1).toString().padLeft(5, '0')}';
// CHANGE THIS: Add the second '.child('Quizzes')' to match your DB image
      final quizSnap = await _dbRef.child('Quizzes')
          .child('Quizzes') // This matches your double-layer structure in image_745c9c.png
          .orderByKey()
          .startAt(startKey)
          .limitToFirst(_remainingToday)
          .get();

      if (quizSnap.exists) {
        Map qData = quizSnap.value as Map;
        List<Map<dynamic, dynamic>> sorted = [];
        var keys = qData.keys.toList()..sort();
        for (var key in keys) sorted.add(Map<dynamic, dynamic>.from(qData[key]));

        setState(() {
          _dailyQuizzes = sorted;
        });
        _startTimer();
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timerSeconds > 0) {
            _timerSeconds--;
          } else {
            _handleAnswer(-1); // Resets streak on timeout
          }
        });
      }
    });
  }

  Future<void> _handleAnswer(int index) async {
    if (_isAnswered || _dailyQuizzes.isEmpty) return;
    _timer?.cancel();

    setState(() {
      _selectedAnswerIndex = index;
      _isAnswered = true;
    });

    bool isCorrect = index != -1 &&
        _dailyQuizzes[_currentQuizIndex]['answers'][index] == _dailyQuizzes[_currentQuizIndex]['correctAnswer'];

    if (isCorrect) {
      _streakCount++; // Increment current streak

      // TRIGGER: Only show dialog if this is the 2nd correct answer in a row
      if (_streakCount >= 2) {
        _streakCount = 0; // Reset streak after the reward
        _showCongratulationsDialog();
      } else {
        // First correct: update database (+2 points) but skip dialog
        await _updateDatabase(true);
        _proceedToNext();
      }
    } else {
      _streakCount = 0; // Reset streak on wrong answer or timeout
      await _updateDatabase(false);
      _proceedToNext();
    }
  }

  void _proceedToNext() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        if (_currentQuizIndex < _dailyQuizzes.length - 1 && _remainingToday > 0) {
          setState(() {
            _currentQuizIndex++;
            _isAnswered = false;
            _selectedAnswerIndex = null;
            _timerSeconds = 20;
          });
          _startTimer();
        } else {
          _showLimitReached();
        }
      }
    });
  }

  // --- Congratulations Dialog ---
  void _showCongratulationsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: const BoxDecoration(
                  color: Color(0xFF9C27B0),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                ),
                child: const Text(
                  "Congratulations !",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              // Robot image from your assets
              Image.asset('Assets/Images/star_robot.png', height: 150),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    // Update DB with 2 points for the correct answer
                    await _updateDatabase(true);
                    _proceedToNext();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C27B0),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Text("Collect Points 🔊", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _proceedToNext();
                },
                child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 15),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateDatabase(bool isCorrect) async {
    final userRef = _dbRef.child('User').child(_deviceId!);
    final progressRef = userRef.child('QuizProgress').child('QuizProgress').child(_today);

    setState(() {
      if (isCorrect) _dbCorrect++; else _dbWrong++;
      _remainingToday--;
    });

    // Award 2 points per correct answer
    await userRef.update({
      'TotalCompletedQuizCount': ServerValue.increment(1),
      'TotalCorrectAnsweredQuizCount': isCorrect ? ServerValue.increment(2) : ServerValue.increment(0),
      'TotalWrongAnsweredQuizCount': !isCorrect ? ServerValue.increment(1) : ServerValue.increment(0),
    });

    await progressRef.update({
      'CorrectQuizCount': _dbCorrect,
      'WrongQuizCount': _dbWrong,
      'RemainingQuizCount': _remainingToday,
      'Date': _today,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const BottomNavigation(currentIndex: 1),
      body: _deviceId == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF9C27B0)))
          : _buildQuizLayout(),
    );
  }

  Widget _buildQuizLayout() {
    String question = _dailyQuizzes.isEmpty ? "Loading Question..." : _dailyQuizzes[_currentQuizIndex]['question'];
    List<dynamic> answers = _dailyQuizzes.isEmpty ? ["...", "...", "...", "..."] : _dailyQuizzes[_currentQuizIndex]['answers'];

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
                    _buildHeaderprofile(),
                    Positioned(top: 180, child: _buildQuestionCard(context, question)),
                    Positioned(top: 150, child: _buildCircularTimer()),
                  ],
                ),
                const SizedBox(height: 70),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: List.generate(answers.length, (index) {
                      String correct = _dailyQuizzes.isEmpty ? "" : _dailyQuizzes[_currentQuizIndex]['correctAnswer'];
                      return _buildAnswerOption(answers[index].toString(), index, correct);
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircularTimer() {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 75, height: 75,
          child: CircularProgressIndicator(
            value: _timerSeconds / 20,
            strokeWidth: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9C27B0)),
          ),
        ),
        Container(
          width: 65, height: 65,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text("$_timerSeconds", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF9C27B0))),
        ),
      ],
    );
  }

  Widget _buildAnswerOption(String text, int index, String correctText) {
    Color bgColor = Colors.white;
    Color textColor = Colors.black87;

    if (_isAnswered) {
      if (text == correctText) {
        bgColor = const Color(0xFF2E7D32); textColor = Colors.white;
      } else if (_selectedAnswerIndex == index) {
        bgColor = const Color(0xFFC62828); textColor = Colors.white;
      }
    }
//answers
    return GestureDetector(
      onTap: () => _handleAnswer(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        width: double.infinity, height: 55,
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300, width: 1.5)),
        child: Center(child: Text(text,textAlign: TextAlign.center, style: TextStyle(color: textColor, fontFamily: "SinhalaBold", fontSize: 15, fontWeight: FontWeight.w600))),
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, String question) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProgressBar("$_dbWrong", Colors.red),
              _buildProgressBar("$_dbCorrect", Colors.green),
            ],
          ),
          const SizedBox(height: 30),
          Text(question, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontFamily: "SinhalaBold", fontWeight: FontWeight.bold, color: Color(0xFF605454))),
          const SizedBox(height: 20),
          Align(alignment: Alignment.bottomCenter, child: Container(height: 10, width: 100, decoration: const BoxDecoration(color: Color(0xFF9C27B0), borderRadius: BorderRadius.vertical(top: Radius.circular(10))))),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String value, Color color) {
    double progress = (int.parse(value) / 20).clamp(0.0, 1.0);
    return Row(
      children: [
        if (color == Colors.red) Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        const SizedBox(width: 5),
        Container(
          width: 70, height: 10,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10))),
          ),
        ),
        const SizedBox(width: 5),
        if (color == Colors.green) Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildHeaderprofile() {
    return Container(
      margin: const EdgeInsets.all(10), height: 300, width: double.infinity,
      decoration: const BoxDecoration(color: Color(0xFF9C27B0), borderRadius: BorderRadius.all(Radius.circular(40))),
      child: Stack(
        children: [
          ..._buildFullStarPattern(rows: 6, columns: 4),
          Positioned(
            top: 15, right: 25,
            child: GestureDetector(
              onTap: () {
                _timer?.cancel();
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())).then((_) => _startTimer());
              },
              child: const CircleAvatar(radius: 22, backgroundImage: AssetImage('Assets/Images/avatar.png'), backgroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFullStarPattern({required int rows, required int columns}) {
    List<Widget> stars = [];
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        stars.add(Positioned(top: (i * 90).toDouble() - 10, left: (j * 110).toDouble() - 10, child: Opacity(opacity: 0.2, child: Image.asset('Assets/Images/star2.png', width: (i+j)%2==0?70:40))));
      }
    }
    return stars;
  }

  // --- Reach Daily Limit Dialog (Matches image_4e9e86.png) ---
  void _showLimitReached() {
    _timer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: const BoxDecoration(
                  color: Color(0xFF9C27B0),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                ),
                child: const Text(
                  "Reach Daily Limit",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              // Use the limit robot image if available, else standard robot
              Image.asset('Assets/Images/dailylimitrobot.png', height: 150),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C27B0),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Text("Come Tomorrow", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade400,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Text("Cancel", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 15),
            ],
          ),
        );
      },
    );
  }
}