import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../Ads/banner_ad_manager.dart';
import '../Widgets/BottomNavigationBar.dart';

class HerosScreen extends StatefulWidget {
  const HerosScreen({super.key});

  @override
  State<HerosScreen> createState() => _HerosScreenState();
}

class _HerosScreenState extends State<HerosScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('User');

  @override
  Widget build(BuildContext context) {
    // Detect orientation to switch between Row (Landscape) and Column (Portrait)
    final orientation = MediaQuery.of(context).orientation;
    final isPortrait = orientation == Orientation.portrait;

    return Scaffold(
      backgroundColor: Colors.white,
      // bottomNavigationBar: const BottomNavigation(currentIndex: 2),
      //banner ad (wraped bottem navigation and banner ad,if want remove below code and remove commented code comment)
      bottomNavigationBar: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MyBannerAdWidget(), // Just one import, one line of code!
          BottomNavigation(currentIndex: 2),
        ],
      ),
      //----------------------------------------------
      body: StreamBuilder(
        stream: _dbRef.onValue, // Real-time listener for leaderboard
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          List<Map<String, dynamic>> topThree = [];
          List<Map<String, dynamic>> rankingList = [];

          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            Map<dynamic, dynamic> usersMap = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
            List<Map<String, dynamic>> sortedUsers = [];

            usersMap.forEach((key, value) {
              sortedUsers.add(Map<String, dynamic>.from(value));
            });

            // Sorting logic based on total correct answers
            sortedUsers.sort((a, b) =>
                (b['MyPoints'] ?? 0).compareTo(a['MyPoints'] ?? 0));

            topThree = sortedUsers.take(3).toList();
            rankingList = sortedUsers.length > 3 ? sortedUsers.sublist(3) : [];
          }

          return Column(
              children: [
              const SizedBox(height: 35),
               Expanded(
                child: isPortrait
                ? _buildPortraitLayout(topThree, rankingList)
                : _buildLandscapeLayout(topThree, rankingList),
               )
            ]
          );

        },
      ),
    );
  }

  // --- PORTRAIT LAYOUT ---
  Widget _buildPortraitLayout(List<Map<String, dynamic>> topThree, List<Map<String, dynamic>> rankingList) {
    return Column(
      children: [
        const SizedBox(height: 0),
        _buildPodiumHeader(topThree, isLandscape: false),
        const SizedBox(height: 10),
        const Text(
          "Hero Ranking",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF635E64)),
        ),
        const SizedBox(height: 10),
        Expanded(child: _buildRankingListView(rankingList)),
      ],
    );
  }

  // --- LANDSCAPE LAYOUT ---
  Widget _buildLandscapeLayout(List<Map<String, dynamic>> topThree, List<Map<String, dynamic>> rankingList) {
    return Row(
      children: [
        // Podium on the left
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: _buildPodiumHeader(topThree, isLandscape: true),
          ),
        ),
        // Ranking list on the right
        Expanded(
          flex: 3,
          child: Column(
            children: [
              const SizedBox(height: 10),
              const Text(
                "Hero Ranking",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF635E64)),
              ),
              Expanded(child: _buildRankingListView(rankingList)),
            ],
          ),
        ),
      ],
    );
  }

  // --- Common Ranking List Widget ---
  Widget _buildRankingListView(List<Map<String, dynamic>> rankingList) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      itemCount: rankingList.isEmpty ? 5 : rankingList.length,
      itemBuilder: (context, index) {
        String rank = (index + 4).toString().padLeft(2, '0');
        String name = rankingList.isEmpty ? "Loading..." : (rankingList[index]['UserName'] ?? "Visitor");
        String? imgPath = rankingList.isEmpty ? null : rankingList[index]['ProfileImage'];
        return _buildRankingTile(rank, name, imgPath);
      },
    );
  }

  // --- Podium Header Section ---
  Widget _buildPodiumHeader(List<Map<String, dynamic>> topThree, {required bool isLandscape}) {
    String firstPlace = topThree.isNotEmpty ? (topThree[0]['UserName'] ?? "").split(" ")[0] : "...";
    String secondPlace = topThree.length > 2 ? (topThree[2]['UserName'] ?? "").split(" ")[0] : "...";
    String thirdPlace = topThree.length > 1 ? (topThree[1]['UserName'] ?? "").split(" ")[0] : "...";
// FETCH IMAGE PATHS FOR TOP 3
    String? firstImg = topThree.isNotEmpty ? topThree[0]['ProfileImage'] : null;
    String? secondImg = topThree.length > 2 ? topThree[2]['ProfileImage'] : null;
    String? thirdImg = topThree.length > 1 ? topThree[1]['ProfileImage'] : null;
    return Container(
      margin: const EdgeInsets.all(10),
      height: isLandscape ? 300 : 420, // Responsive height adjustment
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF9C27B0),
        borderRadius: BorderRadius.all(Radius.circular(40)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ..._buildFullStarPattern(rows: 5, columns: 4),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isLandscape) const SizedBox(height: 30),
              Text("Hero’s", style: TextStyle(fontSize: isLandscape ? 32 : 48, fontWeight: FontWeight.w900, color: Colors.white)),
              Text("Today hero is $firstPlace", style: TextStyle(fontSize: isLandscape ? 16 : 22, fontStyle: FontStyle.italic, color: Colors.white)),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildAnimatedPodiumBar(secondPlace,secondImg, isLandscape ? 60 : 80, 1200),
                  const SizedBox(width: 15),
                  _buildAnimatedPodiumBar(firstPlace,firstImg, isLandscape ? 110 : 150, 1500, isWinner: true),
                  const SizedBox(width: 15),
                  _buildAnimatedPodiumBar(thirdPlace,thirdImg, isLandscape ? 85 : 110, 1000),
                ],
              ),

            ],
          ),
        ],
      ),
    );
  }

  // --- Animated Podium Bar ---
  Widget _buildAnimatedPodiumBar(String name, String? imgPath, double targetHeight, int durationMs, {bool isWinner = false}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: targetHeight),
      duration: Duration(milliseconds: durationMs),
      curve: Curves.easeOutQuart,
      builder: (context, height, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Opacity(
              opacity: (height / targetHeight).clamp(0.0, 1.0),
              child: CircleAvatar(
                radius: isWinner ? 35 : 28,
                backgroundColor: Colors.white,
                // DYNAMIC AVATAR LOGIC
                backgroundImage: AssetImage(
                    (imgPath == null || imgPath.isEmpty) ? 'Assets/Images/avatar.png' : imgPath
                ),
              ),
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(5)),
              child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 10)),
            ),
            const SizedBox(height: 10),
            Container(
              width: 50,
              height: height,
              decoration: const BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- Ranking Tile Widget ---
  Widget _buildRankingTile(String rank, String name, String? imgPath) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 60,
      decoration: BoxDecoration(color: const Color(0xFFCE93D8), borderRadius: BorderRadius.circular(5)),
      child: Row(
        children: [
          Container(width: 10, height: 50, decoration: const BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10)))),
          const SizedBox(width: 15),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white24,
            // DYNAMIC AVATAR LOGIC
            backgroundImage: AssetImage(
                (imgPath == null || imgPath.isEmpty) ? 'Assets/Images/avatar.png' : imgPath
            ),
          ),
          const SizedBox(width: 15),
          Expanded(child: Text(name, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
          Text(rank, style: const TextStyle(color: Color(0xFF9C27B0), fontWeight: FontWeight.w900, fontSize: 20)),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  // --- Background Star Pattern ---
  List<Widget> _buildFullStarPattern({required int rows, required int columns}) {
    List<Widget> stars = [];
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        stars.add(Positioned(top: (i * 90).toDouble() - 10, left: (j * 110).toDouble() - 10, child: Opacity(opacity: 0.3, child: Image.asset('Assets/Images/star2.png', width: (i + j) % 2 == 0 ? 80 : 50))));
      }
    }
    return stars;
  }
}