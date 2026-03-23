import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../../Ads/banner_ad_manager.dart';
import '../../Ads/interstitial_ad_manager.dart';
import '../../Ads/rewarded_ad_manager.dart';
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
  final RewardedAdManager _adManager = RewardedAdManager();
  final InterstitialAdManager _interstitialAdManager = InterstitialAdManager();

  // Logic State
  List<Map<dynamic, dynamic>> _dailyQuizzes = [];
  int _currentQuizIndex = 0;
  String? _deviceId;
  String _today = DateFormat('dd-MM-yyyy').format(DateTime.now());
  String? _profileImageUrl;

  // Timer & Answer State
  int _timerSeconds = 20;
  Timer? _timer;
  bool _isAnswered = false;
  int? _selectedAnswerIndex;

  // Real-time Progress Stats
  int _dbCorrect = 0;
  int _dbWrong = 0;
  int _remainingToday = 20;

  // UPDATED: Used for alternating ad logic and tracking rounds
  int _extraRoundsClaimed = 0;

  // Streak Tracking Logic
  int _streakCount = 0;

  @override
  void initState() {
    super.initState();
    _adManager.loadAd();
    _interstitialAdManager.loadAd();
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
    } else if (state == AppLifecycleState.resumed) {
      if (!_adManager.isLoaded) _adManager.loadAd();
      if (!_interstitialAdManager.isLoaded) _interstitialAdManager.loadAd();

      if (!_isAnswered && _dailyQuizzes.isNotEmpty) {
        _startTimer();
      }
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

      setState(() {
        _profileImageUrl = data['ProfileImage'];
      });

      int totalCompleted = data['TotalCompletedQuizCount'] ?? 0;

      var dailyNode = data['QuizProgress']?['QuizProgress']?[_today];
      if (dailyNode != null) {
        _remainingToday = dailyNode['RemainingQuizCount'] ?? 20;
        _dbCorrect = dailyNode['CorrectQuizCount'] ?? 0;
        _dbWrong = dailyNode['WrongQuizCount'] ?? 0;
        _extraRoundsClaimed = dailyNode['ExtraRoundsClaimed'] ?? 0;
      }

      if (_remainingToday <= 0) {
        setState(() => _dailyQuizzes = []);
        _showLimitReached();
        return;
      }

      String startKey = 'quiz${(totalCompleted + 1).toString().padLeft(5, '0')}';
      final quizSnap = await _dbRef
          .child('Quizzes')
          .child('Quizzes')
          .orderByKey()
          .startAt(startKey)
          .limitToFirst(_remainingToday)
          .get();

      if (quizSnap.exists) {
        Map qData = quizSnap.value as Map;
        List<Map<dynamic, dynamic>> sorted = [];
        var keys = qData.keys.toList()..sort();
        for (var key in keys) {
          sorted.add(Map<dynamic, dynamic>.from(qData[key]));
        }

        setState(() {
          _dailyQuizzes = sorted;
          _currentQuizIndex = 0;
          _isAnswered = false;
          _selectedAnswerIndex = null;
          _timerSeconds = 20;
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
            _handleAnswer(-1);
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
        _dailyQuizzes[_currentQuizIndex]['answers'][index] ==
            _dailyQuizzes[_currentQuizIndex]['correctAnswer'];

    if (isCorrect) {
      _streakCount++;
      if (_streakCount >= 2) {
        _showCongratulationsDialog();
      } else {
        await _updateDatabase(true, points: 1);
        _proceedToNext();
      }
    } else {
      _streakCount = 0;
      await _updateDatabase(false, points: 0);
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
                child: const Text("Congratulations !",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
              Image.asset('Assets/Images/star_robot.png', height: 150),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text("කෙටි වීඩියෝවක් නරඹා පොයින්ට් 4ක් වැඩිපුර ලබාගන්න\nWatch a short video to collect 4 Points!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,)),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: !_adManager.isLoaded
                      ? null
                      : () {
                    _adManager.showAd(onRewardEarned: () async {
                      if (mounted) {
                        Navigator.pop(context);
                        await _updateDatabase(true, points: 4);
                        final userSnap = await _dbRef.child('User').child(_deviceId!).get();
                        int currentBalance = (userSnap.value as Map)['MyPoints'] ?? 0;
                        _showSuccessDialog(4, currentBalance);
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _adManager.isLoaded ? const Color(0xFF9C27B0) : Colors.grey.shade400,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: _adManager.isLoaded
                      ? const Text("පොයින්ට්  ලබාගන්න\nCollect Points",textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 13,fontWeight: FontWeight.bold))
                      : const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    _streakCount = 0;
                    await _updateDatabase(true, points: 1);
                    _proceedToNext();
                  },
                  style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFBDBDBD),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                  child: const Text ("එපා\nCancel",textAlign: TextAlign.center, style: TextStyle (color: Colors.white,  fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 15),
            ],
          ),
        );
      },
    );
  }

  // UPDATED: This section now handles alternating ads and unlimited quizzes
  void _showLimitReached() {
    _timer?.cancel();
    Timer? adRetryTimer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {

            // LOGIC: Alternating Ad Type based on rounds
            bool isInterstitialRound = _extraRoundsClaimed % 2 == 0;
            bool adReady = isInterstitialRound ? _interstitialAdManager.isLoaded : _adManager.isLoaded;

            if (!adReady && adRetryTimer == null) {
              adRetryTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
                if (isInterstitialRound) _interstitialAdManager.loadAd(); else _adManager.loadAd();
                if (mounted) setStateDialog(() {});
              });
            }

            // UI Strings - Always offering 20 now (Unlimited)
            String title = "වැඩිපුර ප්‍රශ්න ලබාගන්න\nGet More Quizzes";
            String subTitle = "තවත් ප්‍රශ්න 20ක් ලබාගන්න කෙටි වීඩියෝවක් නරඹන්න\nWatch small video to get 20 more quizzes!";
            String buttonText = "ප්‍රශ්න 20ක් ලබාගන්න\nGet 20 Quizzes";
            int bonusAmount = 20;

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
                    child: Text(title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                  Image.asset('Assets/Images/dailylimitrobot.png', height: 150),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(subTitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(height: 20),

                  // BUTTON 1: Get Quizzes (Triggers Ad)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ElevatedButton(
                      onPressed: !adReady ? null : () {
                        adRetryTimer?.cancel();
                        if (isInterstitialRound) {
                          // Show Interstitial
                          _interstitialAdManager.showAd(onAdDismissed: () => _handleAdSuccess(bonusAmount));
                        } else {
                          // Show Rewarded
                          _adManager.showAd(onRewardEarned: () => _handleAdSuccess(bonusAmount));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: adReady ? const Color(0xFF9C27B0) : Colors.grey.shade400,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: adReady
                          ? Text(buttonText, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold))
                          : const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // BUTTON 2: Come Tomorrow (Cancel)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ElevatedButton(
                      onPressed: () {
                        adRetryTimer?.cancel();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade400,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                      child: const Text("හෙට උත්සහාකරන්න\nCome Tomorrow",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            );
          },
        );
      },
    ).then((_) => adRetryTimer?.cancel());
  }

  // UPDATED: Centralized handler to process success after any ad type
  void _handleAdSuccess(int bonusAmount) async {
    if (!mounted) return;

    // Check if dialog is still open before popping
    if (ModalRoute.of(context)?.isCurrent == false) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    setState(() {
      _extraRoundsClaimed++;
      _remainingToday = bonusAmount;
    });

    await _dbRef.child('User').child(_deviceId!).child('QuizProgress').child('QuizProgress').child(_today).update({
      'RemainingQuizCount': bonusAmount,
      'ExtraRoundsClaimed': _extraRoundsClaimed,
    });

    _showBonusSuccessDialog(bonusAmount);
  }

  void _showBonusSuccessDialog(int amount) {
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
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
                child: const Text("Success!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
              Image.asset('Assets/Images/robot_gold.png', height: 120),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text("ඔබට තවත් ප්‍රශ්න $amount ක් ලැබුණි!\nStart answering now.",
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 25),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _loadUserAndQuizzes();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C27B0),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                  child: const Text("Start / ආරම්භ කරන්න", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessDialog(int earned, int totalBalance) {
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
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
                child: const Text("Wow.. You earnd",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
              Image.asset('Assets/Images/robot_gold.png', height: 100),
              const SizedBox(height: 15),
              Text("You earned $earned extra points", style: const TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Your point balance", style: TextStyle(fontSize: 14, color: Colors.black54)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Color(0xFFE1BEE7), shape: BoxShape.circle),
                    child: Text("$totalBalance", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF9C27B0))),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _streakCount = 0;
                    _proceedToNext();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C27B0),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                  child: const Text("Continue", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateDatabase(bool isCorrect, {int points = 0}) async {
    final userRef = _dbRef.child('User').child(_deviceId!);
    final progressRef = userRef.child('QuizProgress').child('QuizProgress').child(_today);

    bool isCompetitionActive = false;
    try {
      final compSnap = await _dbRef.child('Competition').get();
      if (compSnap.exists) {
        Map compData = compSnap.value as Map;
        DateTime now = DateTime.now();
        DateTime start = _parseDateTime(compData['StartDate'], compData['StartTime']);
        DateTime end = _parseDateTime(compData['EndDate'], compData['EndTime']);
        if (now.isAfter(start) && now.isBefore(end)) isCompetitionActive = true;
      }
    } catch (e) {
      debugPrint("Error checking competition status: $e");
    }

    setState(() {
      if (isCorrect) _dbCorrect++; else _dbWrong++;
      _remainingToday--;
    });

    Map<String, Object?> userUpdates = {
      'TotalCompletedQuizCount': ServerValue.increment(1),
      'MyPoints': ServerValue.increment(points),
      'TotalWrongAnsweredQuizCount': !isCorrect ? ServerValue.increment(1) : ServerValue.increment(0),
    };

    if (isCorrect) {
      userUpdates['TotalCorrectAnsweredQuizCount'] = ServerValue.increment(1);
      if (isCompetitionActive) userUpdates['CompetitionPoints'] = ServerValue.increment(points);
    }

    await userRef.update(userUpdates);
    await progressRef.update({
      'CorrectQuizCount': _dbCorrect,
      'WrongQuizCount': _dbWrong,
      'RemainingQuizCount': _remainingToday,
      'Date': _today,
      'ExtraRoundsClaimed': _extraRoundsClaimed,
    });
  }

  DateTime _parseDateTime(String? date, String? time) {
    try {
      if (date == null || time == null) return DateTime(2000);
      List<String> d = date.split("-");
      List<String> t = time.split(":");
      return DateTime(int.parse(d[2]), int.parse(d[1]), int.parse(d[0]), int.parse(t[0]), int.parse(t[1]));
    } catch (e) {
      return DateTime(2000);
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
          BottomNavigation(currentIndex: 1),
        ],
      ),
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
    return Stack(alignment: Alignment.center, children: [
      SizedBox(
          width: 75,
          height: 75,
          child: CircularProgressIndicator(
              value: _timerSeconds / 20,
              strokeWidth: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9C27B0)))),
      Container(
          width: 65,
          height: 65,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text("$_timerSeconds",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF9C27B0)))),
    ]);
  }

  Widget _buildAnswerOption(String text, int index, String correctText) {
    Color bgColor = Colors.white;
    Color textColor = Colors.black87;
    if (_isAnswered) {
      if (text == correctText) {
        bgColor = const Color(0xFF2E7D32);
        textColor = Colors.white;
      } else if (_selectedAnswerIndex == index) {
        bgColor = const Color(0xFFC62828);
        textColor = Colors.white;
      }
    }
    return GestureDetector(
      onTap: () => _handleAnswer(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade300, width: 1.5)),
        child: Center(
            child: Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: textColor, fontFamily: "SinhalaBold", fontSize: 15, fontWeight: FontWeight.w600))),
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, String question) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)]),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _buildProgressBar("$_dbWrong", Colors.red),
          _buildProgressBar("$_dbCorrect", Colors.green)
        ]),
        const SizedBox(height: 30),
        Text(question,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 20, fontFamily: "SinhalaBold", fontWeight: FontWeight.bold, color: Color(0xFF605454))),
        const SizedBox(height: 20),
        Align(
            alignment: Alignment.bottomCenter,
            child: Container(
                height: 10,
                width: 100,
                decoration: const BoxDecoration(
                    color: Color(0xFF9C27B0), borderRadius: BorderRadius.vertical(top: Radius.circular(10))))),
      ]),
    );
  }

  Widget _buildProgressBar(String value, Color color) {
    // 1. Calculate the total answered so far
    int totalAnswered = _dbCorrect + _dbWrong;

    // 2. Calculate the progress based on accuracy percentage
    double progress = 0.0;
    if (totalAnswered > 0) {
      progress = (int.parse(value) / totalAnswered).clamp(0.0, 1.0);
    }

    return Row(children: [
      if (color == Colors.red) Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      const SizedBox(width: 5),
      Container(
          width: 70,
          height: 10,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10))))),
      const SizedBox(width: 5),
      if (color == Colors.green) Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _buildHeaderprofile() {
    return Container(
      margin: const EdgeInsets.all(10),
      height: 300,
      width: double.infinity,
      decoration: const BoxDecoration(
          color: Color(0xFF9C27B0), borderRadius: BorderRadius.all(Radius.circular(40))),
      child: Stack(children: [
        ..._buildFullStarPattern(rows: 6, columns: 4),
        Positioned(
            top: 15,
            right: 25,
            child: Stack(alignment: Alignment.center, children: [
              const CircleAvatar(radius: 24, backgroundColor: Color(0xFFFFFFFF)),
              GestureDetector(
                  onTap: () {
                    _timer?.cancel();
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))
                        .then((_) {
                      _loadUserAndQuizzes();
                      _startTimer();
                    });
                  },
                  child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white24,
                      backgroundImage: AssetImage((_profileImageUrl == null || _profileImageUrl!.isEmpty)
                          ? 'Assets/Images/avatar.png'
                          : _profileImageUrl!))),
            ])),
      ]),
    );
  }

  List<Widget> _buildFullStarPattern({required int rows, required int columns}) {
    List<Widget> stars = [];
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        stars.add(Positioned(
            top: (i * 90).toDouble() - 10,
            left: (j * 110).toDouble() - 10,
            child: Opacity(
                opacity: 0.2,
                child: Image.asset('Assets/Images/star2.png', width: (i + j) % 2 == 0 ? 70 : 40))));
      }
    }
    return stars;
  }
}