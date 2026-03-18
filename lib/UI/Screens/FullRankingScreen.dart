import 'package:flutter/material.dart';
import '../../Ads/banner_ad_manager.dart';

class FullRankingScreen extends StatelessWidget {
  final List<Map<String, dynamic>> fullList;
  final bool isAllTime; // Added to identify which points to show

  const FullRankingScreen({
    super.key,
    required this.fullList,
    required this.isAllTime
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
            isAllTime ? "All Time Heroes" : "Competition Heroes",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        backgroundColor: const Color(0xFF9C27B0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      bottomNavigationBar: const MyBannerAdWidget(),
      body: Column(
        children: [
          // Info Bar
          Container(
            padding: const EdgeInsets.all(15),
            color: const Color(0xFF9C27B0).withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.emoji_events_outlined, color: Color(0xFF9C27B0), size: 20),
                const SizedBox(width: 10),
                Text(
                  "Total Heroes Ranked: ${fullList.length}",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF9C27B0)),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              itemCount: fullList.length,
              itemBuilder: (context, index) {
                // Rank starts from 1 for the very first item
                String rank = (index + 1).toString().padLeft(2, '0');

                var user = fullList[index];
                String name = user['UserName'] ?? "Visitor";

                // Logic to select correct points based on toggle
                int points = isAllTime
                    ? (user['MyPoints'] ?? 0)
                    : (user['CompetitionPoints'] ?? 0);

                String? imgPath = user['ProfileImage'];

                return _buildFullRankingTile(rank, name, imgPath, points);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullRankingTile(String rank, String name, String? imgPath, int points) {
    // Special colors for Top 3
    Color tileColor = const Color(0xFFCE93D8);
    if (rank == "01") tileColor = const Color(0xFF9C27B0);
    if (rank == "02") tileColor = const Color(0xFFAA47BC);
    if (rank == "03") tileColor = const Color(0xFFBA68C8);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 70,
      decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4)
            )
          ]
      ),
      child: Row(
        children: [
          // White side accent
          Container(
              width: 8,
              height: 40,
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topRight: Radius.circular(10),
                      bottomRight: Radius.circular(10)
                  )
              )
          ),
          const SizedBox(width: 15),
          // User Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white24,
            backgroundImage: AssetImage(
                (imgPath == null || imgPath.isEmpty)
                    ? 'Assets/Images/avatar.png'
                    : imgPath
            ),
          ),
          const SizedBox(width: 15),
          // Name and Points
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
                        fontSize: 17
                    )
                ),
                Text("$points Points",
                    style: const TextStyle(color: Colors.white70, fontSize: 13)
                ),
              ],
            ),
          ),
          // Rank Number
          Text(rank,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 24
              )
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }
}