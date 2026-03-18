import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:braita_new/Services/DatabaseService.dart';
import '../../Ads/banner_ad_manager.dart';
import '../Widgets/BottomNavigationBar.dart';
import 'FullRankingScreen.dart';
import 'dart:async';

class HerosScreen extends StatefulWidget {
  const HerosScreen({super.key});

  @override
  State<HerosScreen> createState() => _HerosScreenState();
}

class _HerosScreenState extends State<HerosScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final DatabaseService _dbService = DatabaseService();
  String? _myDeviceId;
  bool _isAllTimeSelected = true;
  Timer? _timer;
  DateTime _now = DateTime.now();
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadDeviceId() async {
    String? rawId = await _dbService.getDeviceId();
    if (rawId != null) {
      setState(() {
        _myDeviceId = rawId.replaceAll(RegExp(r'[.#$\[\]]'), '_');
      });
    }
  }

  void _showWinnerDialog(String winnerName, String? imgPath) {
    if (_dialogShown) return;
    _dialogShown = true;

    showDialog(
      context: context,
      barrierDismissible: true,
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
                child: const Text("Congratulations !",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset('Assets/Images/star_robot.png',
                      height: 180,
                      errorBuilder: (c, e, s) => const SizedBox(height: 180)),
                  Image.asset('Assets/Images/star_robot.png', height: 130),
                ],
              ),
              const SizedBox(height: 10),
              Text("$winnerName Is the winner of\nthis time Competition",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF635E64))),
              Text("මෙවර ජයග්‍රාහකයා $winnerName",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 10),
              const Text("ත්‍යාගය ලබාගන්න ඔබේ\nගිණුමේ විස්තර සම්පූර්ණ කරන්න",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.red,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStepCircle("1", "Go to\nprofile"),
                  _buildStepArrow(),
                  _buildStepCircle("2", "Click\nEdit Profile"),
                  _buildStepArrow(),
                  _buildStepCircle("3", "Enter\nData"),
                ],
              ),
              const SizedBox(height: 25),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepCircle(String num, String label) {
    return Column(
      children: [
        CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF9C27B0),
            child: Text(num, style: const TextStyle(color: Colors.white))),
        const SizedBox(height: 5),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    );
  }

  Widget _buildStepArrow() {
    return const Padding(
      padding: EdgeInsets.only(left: 8, right: 8, bottom: 25),
      child: Icon(Icons.arrow_forward, color: Color(0xFF9C27B0), size: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MyBannerAdWidget(),
          BottomNavigation(currentIndex: 2),
        ],
      ),
      body: StreamBuilder(
        stream: _dbRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          List<Map<String, dynamic>> topThree = [];
          List<Map<String, dynamic>> rankingList = [];
          int myRank = 0;
          int myPoints = 0;

          // Time variables
          String dVal = "00", hVal = "00", mVal = "00", sVal = "00";
          bool isPending = false;
          bool isFinished = false;
          Map compData = {}; // Initialize empty map

          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            final rawData = snapshot.data!.snapshot.value;
            if (rawData is! Map)
              return const Center(child: CircularProgressIndicator());

            Map data = Map<dynamic, dynamic>.from(rawData);
            Map usersMap = data['User'] is Map ? data['User'] : {};
            compData = data['Competition'] is Map ? data['Competition'] : {};

            DateTime start =
            _parseDateTime(compData['StartDate'], compData['StartTime']);
            DateTime end =
            _parseDateTime(compData['EndDate'], compData['EndTime']);

            if (start.year != 2000 && _now.isBefore(start)) {
              isPending = true;
              Duration diff = start.difference(_now);
              dVal = diff.inDays.toString().padLeft(2, '0');
              hVal = diff.inHours.remainder(24).toString().padLeft(2, '0');
              mVal = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
              sVal = diff.inSeconds.remainder(60).toString().padLeft(2, '0');
            } else if (end.year != 2000 && _now.isAfter(end)) {
              isFinished = true;
            }

            List<Map<String, dynamic>> sortedUsers = [];
            usersMap.forEach((key, value) {
              if (value is Map) {
                var user = Map<String, dynamic>.from(value);
                user['id'] = key;
                sortedUsers.add(user);
              }
            });

            if (_isAllTimeSelected) {
              sortedUsers.sort(
                      (a, b) => (b['MyPoints'] ?? 0).compareTo(a['MyPoints'] ?? 0));
            } else {
              sortedUsers.sort((a, b) => (b['CompetitionPoints'] ?? 0)
                  .compareTo(a['CompetitionPoints'] ?? 0));
            }

            if (_myDeviceId != null) {
              myRank =
                  sortedUsers.indexWhere((u) => u['id'] == _myDeviceId) + 1;
              if (myRank > 0) {
                myPoints = _isAllTimeSelected
                    ? (sortedUsers[myRank - 1]['MyPoints'] ?? 0)
                    : (sortedUsers[myRank - 1]['CompetitionPoints'] ?? 0);
              }
            }

            topThree = sortedUsers.take(3).toList();
            rankingList = sortedUsers.length > 3 ? sortedUsers.sublist(3) : [];

            if (isFinished && !_isAllTimeSelected && topThree.isNotEmpty) {
              Future.delayed(
                  Duration.zero,
                      () => _showWinnerDialog(topThree[0]['UserName'] ?? "Winner",
                      topThree[0]['ProfileImage']));
            }
          }

          return Column(
            children: [
              const SizedBox(height: 35),
              _buildPodiumHeader(topThree, myRank, myPoints, dVal, hVal, mVal,
                  sVal, isPending, compData),
              const SizedBox(height: 10),
              _buildToggleButtons(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                // child: Divider(color: Colors.grey, thickness: 1),
              ),

              Expanded(child: _buildRankingListView(rankingList, topThree)),
            ],
          );
        },
      ),
    );
  }

  DateTime _parseDateTime(String? date, String? time) {
    try {
      if (date == null || time == null) return DateTime(2000);
      List<String> d = date.split("-");
      List<String> t = time.split(":");
      return DateTime(int.parse(d[2]), int.parse(d[1]), int.parse(d[0]),
          int.parse(t[0]), int.parse(t[1]));
    } catch (e) {
      return DateTime(2000);
    }
  }

  Widget _buildPodiumHeader(
      List<Map<String, dynamic>> topThree,
      int myRank,
      int myPoints,
      String d,
      String h,
      String m,
      String s,
      bool isPending,
      Map compData) {
    // --- NEW LOGIC FOR ENDING COUNTDOWN ---
    String endD = "00", endH = "00", endM = "00", endS = "00";
    bool isLive = false;

    if (compData.isNotEmpty) {
      DateTime end =
      _parseDateTime(compData['EndDate'], compData['EndTime']);
      DateTime start =
      _parseDateTime(compData['StartDate'], compData['StartTime']);

      if (_now.isAfter(start) && _now.isBefore(end)) {
        isLive = true;
        Duration diff = end.difference(_now);
        endD = diff.inDays.toString().padLeft(2, '0');
        endH = diff.inHours.remainder(24).toString().padLeft(2, '0');
        endM = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
        endS = diff.inSeconds.remainder(60).toString().padLeft(2, '0');
      }
    }

    String firstPlace = topThree.isNotEmpty
        ? (topThree[0]['UserName'] ?? "").split(" ")[0]
        : "...";
    int getPts(int i) => (topThree.length > i)
        ? (_isAllTimeSelected
        ? (topThree[i]['MyPoints'] ?? 0)
        : (topThree[i]['CompetitionPoints'] ?? 0))
        : 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      height: 390,
      width: double.infinity,
      decoration: const BoxDecoration(
          color: Color(0xFF9C27B0),
          borderRadius: BorderRadius.all(Radius.circular(40))),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ..._buildFullStarPattern(rows: 5, columns: 4),
          Column(
            children: [
              const SizedBox(height: 15),
              const Text("Hero’s",
                  style: TextStyle(
                      height: 0.9,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
              if (isPending && !_isAllTimeSelected) ...[
                const SizedBox(height: 20),
                const Text("Quiz competition Start in",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Container(
                  width: 320,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTimeDigit(d),
                          const SizedBox(width: 10),
                          const Text(":",
                              style: TextStyle(
                                  fontSize: 35,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF635E64))),
                          const SizedBox(width: 10),
                          _buildTimeDigit(h),
                          const SizedBox(width: 10),
                          const Text(":",
                              style: TextStyle(
                                  fontSize: 35,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF635E64))),
                          const SizedBox(width: 10),
                          _buildTimeDigit(m),
                          const SizedBox(width: 10),
                          const Text(":",
                              style: TextStyle(
                                  fontSize: 35,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF635E64))),
                          const SizedBox(width: 10),
                          _buildTimeDigit(s),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTimeLabel("Days"),
                          const SizedBox(width: 15),
                          _buildTimeLabel("Hours"),
                          const SizedBox(width: 18),
                          _buildTimeLabel("Minutes"),
                          const SizedBox(width: 20),
                          _buildTimeLabel("Seconds"),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                const Text("Participate and get price",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const Text("This is your time don't miss this",
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ] else ...[
                Text("Today hero is $firstPlace",
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                // NEW: Professional Live Ending Countdown with Labels
                if (isLive && !_isAllTimeSelected)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                    decoration: BoxDecoration(
                     // color: const Color(0xFFD9D9D9), // Light silver/gray background
                      borderRadius: BorderRadius.circular(5),
                    ),

                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // const Text(
                        //   "End in: ",
                        //   style: TextStyle(
                        //       color: Color(0xFF635E64),
                        //       fontWeight: FontWeight.bold,
                        //       fontSize: 10),
                        // ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "$endD:$endH:$endM:$endS",
                              style: const TextStyle(
                                  color: Color(0xFFF2FA02),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: 1.5),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildSmallLabel("Days"),
                                const SizedBox(width: 8),
                                _buildSmallLabel("Hours"),
                                const SizedBox(width: 8),
                                _buildSmallLabel("Min"),
                                const SizedBox(width: 10),
                                _buildSmallLabel("Sec"),
                              ],
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                Row(
                  key: ValueKey(_isAllTimeSelected),
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildAnimatedPodiumBar(
                        topThree.length > 2 ? topThree[2]['UserName'] : "...",
                        topThree.length > 2
                            ? topThree[2]['ProfileImage']
                            : null,
                        getPts(2),
                        70,
                        1200,
                        "03"),
                    const SizedBox(width: 15),
                    _buildAnimatedPodiumBar(
                        firstPlace,
                        topThree.isNotEmpty
                            ? topThree[0]['ProfileImage']
                            : null,
                        getPts(0),
                        130,
                        1500,
                        "01",
                        isWinner: true),
                    const SizedBox(width: 15),
                    _buildAnimatedPodiumBar(
                        topThree.length > 1 ? topThree[1]['UserName'] : "...",
                        topThree.length > 1
                            ? topThree[1]['ProfileImage']
                            : null,
                        getPts(1),
                        100,
                        1000,
                        "02"),
                  ],
                ),
              ],
            ],
          ),
          Positioned(
            bottom: 40,
            right: 15,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.amber,
                  child: Text(myRank.toString().padLeft(2, '0'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18)),
                ),
                const SizedBox(height: 4),
                const Text("My Rank",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDigit(String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(value,
          style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Color(0xFF635E64))),
    );
  }

  Widget _buildTimeLabel(String label) {
    return SizedBox(
      width: 55,
      child: Text(label,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  Widget _buildAnimatedPodiumBar(String name, String? imgPath, int points,
      double targetHeight, int durationMs, String rankNum,
      {bool isWinner = false}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: targetHeight),
      duration: Duration(milliseconds: durationMs),
      curve: Curves.easeOutQuart,
      builder: (context, height, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CircleAvatar(
                radius: isWinner ? 35 : 28,
                backgroundColor: Colors.white,
                backgroundImage: AssetImage((imgPath == null || imgPath.isEmpty)
                    ? 'Assets/Images/avatar.png'
                    : imgPath)),
            const SizedBox(height: 5),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(5)),
                child: Column(children: [
                  Text(name.split(" ")[0],
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                  Text("$points Pts",
                      style: const TextStyle(color: Colors.yellow, fontSize: 8))
                ])),
            const SizedBox(height: 10),
            Container(
                width: 50,
                height: height,
                decoration: const BoxDecoration(
                    color: Colors.white38,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(5),
                        topRight: Radius.circular(5))),
                child: Center(
                    child: Text(rankNum,
                        style: const TextStyle(
                            color: Color(0xFF9C27B0),
                            fontWeight: FontWeight.bold,
                            fontSize: 24)))),
          ],
        );
      },
    );
  }

  Widget _buildToggleButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 55,
      decoration: BoxDecoration(
          color: const Color(0xFFF1F1F1),
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Expanded(
              child:
              _buildTab("All The Time Hero's", _isAllTimeSelected, true)),
          Expanded(
              child:
              _buildTab("Competitions Hero's", !_isAllTimeSelected, false)),
        ],
      ),
    );
  }

  Widget _buildTab(String title, bool isActive, bool isAllTime) {
    return GestureDetector(
      onTap: () => setState(() {
        _isAllTimeSelected = isAllTime;
        _dialogShown = false;
      }),
      child: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF9C27B0).withOpacity(0.7)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(15)),
        child: Text(title,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.grey)),
      ),
    );
  }

  Widget _buildRankingListView(List<Map<String, dynamic>> rankingList,
      List<Map<String, dynamic>> topThree) {
    return Column(
      children: [
        // Updated Row to contain both Title and Expand Button
        Padding(
          padding: const EdgeInsets.fromLTRB(25, 15, 25, 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Hero Ranking",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Color(0xBD884593))),
              GestureDetector(
                  onTap: () {
                    List<Map<String, dynamic>> fullList = [
                      ...topThree,
                      ...rankingList
                    ];
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => FullRankingScreen(
                                fullList: fullList,
                                isAllTime: _isAllTimeSelected)));
                  },
                  child: Container(
                    height: 28,
                    width: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFBCBCBC).withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.open_in_full_rounded,
                      color: Color(0xFF9C27B0),
                      size: 16,
                    ),
                  )),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: rankingList.isEmpty
                ? 0
                : (rankingList.length > 10 ? 10 : rankingList.length),
            itemBuilder: (context, index) {
              String rank = (index + 4).toString().padLeft(2, '0');
              var user = rankingList[index];
              int pts = _isAllTimeSelected
                  ? (user['MyPoints'] ?? 0)
                  : (user['CompetitionPoints'] ?? 0);
              return _buildRankingTile(rank, user['UserName'] ?? "Visitor",
                  user['ProfileImage'], pts);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRankingTile(
      String rank, String name, String? imgPath, int points) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 60,
      decoration: BoxDecoration(
          color: const Color(0xFFCE93D8).withOpacity(0.8),
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Container(
              width: 5,
              height: 35,
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topRight: Radius.circular(5),
                      bottomRight: Radius.circular(5)))),
          const SizedBox(width: 10),
          CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage((imgPath == null || imgPath.isEmpty)
                  ? 'Assets/Images/avatar.png'
                  : imgPath)),
          const SizedBox(width: 15),
          Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    Text("$points Pts",
                        style:
                        const TextStyle(color: Colors.white70, fontSize: 11)),
                  ])),
          Text(rank,
              style: const TextStyle(
                  color: Color(0xFF9C27B0),
                  fontWeight: FontWeight.w900,
                  fontSize: 18)),
          const SizedBox(width: 20),
        ],
      ),
    );
  }
  Widget _buildSmallLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: Colors.grey
      ),
    );
  }
  List<Widget> _buildFullStarPattern(
      {required int rows, required int columns}) {
    List<Widget> stars = [];
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        stars.add(Positioned(
            top: (i * 90).toDouble() - 10,
            left: (j * 110).toDouble() - 10,
            child: Opacity(
                opacity: 0.3,
                child: Image.asset('Assets/Images/star2.png',
                    width: (i + j) % 2 == 0 ? 80 : 50))));
      }
    }
    return stars;
  }
}