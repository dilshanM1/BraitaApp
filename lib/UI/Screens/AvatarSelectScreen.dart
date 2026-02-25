import 'package:flutter/material.dart';

import '../../Ads/interstitial_ad_manager.dart';

class AvatarSelectScreen extends StatefulWidget {
  const AvatarSelectScreen({super.key});

  @override
  State<AvatarSelectScreen> createState() => _AvatarSelectScreenState();
}

class _AvatarSelectScreenState extends State<AvatarSelectScreen> {
  // Hardcoded list of 12 avatars
  final List<String> maleAvatars = List.generate(6, (index) => 'Assets/Avatars/male_${index + 1}.png');
  final List<String> femaleAvatars = List.generate(6, (index) => 'Assets/Avatars/female_${index + 1}.png');
  final InterstitialAdManager _interstitialAdManager = InterstitialAdManager();

  String? selectedAvatar;

  @override
  void initState() {
    super.initState();
    _interstitialAdManager.loadAd();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF9C27B0), // Braita Purple
      body: Stack(
        children: [
          // 1. Background Star Pattern (Stays fixed while content scrolls)
          ..._buildFullStarPattern(rows: 10, columns: 4),

          // 2. Main Scrollable Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildAppBar(context),
                  const Text(
                    "Avatar",
                    style: TextStyle(color: Colors.white, fontSize: 45, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "Select Avatar",
                    style: TextStyle(color: Colors.white70, height: 0.5, fontSize: 18),
                  ),
                  const SizedBox(height: 30),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader("Male"),
                        const SizedBox(height: 15),
                        _buildAvatarGrid(maleAvatars),

                        const SizedBox(height: 30),

                        _buildSectionHeader("Female"),
                        const SizedBox(height: 15),
                        _buildAvatarGrid(femaleAvatars),

                        // Extra space at the bottom so the last row isn't hidden by the button
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Fixed Bottom Action Button
          _buildFloatingBottomButton(),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF9C27B0), size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: Colors.white38, thickness: 1)),
      ],
    );
  }

  Widget _buildAvatarGrid(List<String> avatars) {
    return GridView.builder(
      shrinkWrap: true, // Crucial for using inside SingleChildScrollView
      physics: const NeverScrollableScrollPhysics(), // Let the parent handle scrolling
      itemCount: avatars.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1, // Keeps them perfectly circular
      ),
      itemBuilder: (context, index) {
        bool isSelected = selectedAvatar == avatars[index];
        return GestureDetector(
          onTap: () => setState(() => selectedAvatar = avatars[index]),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.white24,
                width: isSelected ? 4 : 1,
              ),
              boxShadow: isSelected ? [BoxShadow(color: Colors.black38, blurRadius: 10, spreadRadius: 1)] : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 50, // Slightly smaller to fit grid spacing better
                  backgroundColor: Colors.white10,
                  backgroundImage: AssetImage(avatars[index]),
                ),
                if (isSelected)
                  const Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.check, size: 18, color: Color(0xFF9C27B0)),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingBottomButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        // Gradient ensures content behind the button is readable while scrolling
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF9C27B0).withOpacity(0.0),
              const Color(0xFF9C27B0).withOpacity(0.9),
              const Color(0xFF9C27B0),
            ],
          ),
        ),
        child: SafeArea(
          top: false, // We only care about the bottom padding here
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 10, 30, 20), // Standard padding
            child: ElevatedButton(
              onPressed: selectedAvatar == null ? null : () {
                _interstitialAdManager.showAd(
                  onAdDismissed: () {
                    // This code runs AFTER the ad is closed
                    Navigator.pop(context, selectedAvatar);
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                disabledBackgroundColor: Colors.white54,
                minimumSize: const Size(double.infinity, 55),
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text(
                "Add to profile",
                style: TextStyle(
                    color: Color(0xFF9C27B0),
                    fontWeight: FontWeight.bold,
                    fontSize: 18
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFullStarPattern({required int rows, required int columns}) {
    List<Widget> stars = [];
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        stars.add(Positioned(
          top: (i * 150).toDouble(),
          left: (j * 120).toDouble() - 20,
          child: Opacity(
            opacity: 0.15,
            child: Image.asset('Assets/Images/star2.png', width: (i + j) % 2 == 0 ? 100 : 70),
          ),
        ));
      }
    }
    return stars;
  }
}