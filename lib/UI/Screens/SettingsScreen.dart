import 'package:braita_new/UI/Screens/AboutScreen.dart';
import 'package:braita_new/UI/Screens/AvatarSelectScreen.dart';
import 'package:braita_new/UI/Screens/HomeScreen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // For More Apps
import 'package:share_plus/share_plus.dart'; // For Sharing
import '../../Ads/banner_ad_manager.dart';
import '../Widgets/BottomNavigationBar.dart';
import 'AccountDeleteRequest.dart';
import 'PrivacyPolicyScreen.dart';
import 'TermsScreen.dart';
// Import your new pages here
// import 'PrivacyPolicyScreen.dart';
// import 'TermsScreen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Helper function to handle external links
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // bottomNavigationBar: const BottomNavigation(currentIndex: 3),
      //banner ad (wraped bottem navigation and banner ad,if want remove below code and remove commented code comment)
      bottomNavigationBar: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MyBannerAdWidget(), // Just one import, one line of code!
          BottomNavigation(currentIndex: 3),
        ],
      ),
      //----------------------------------------------
      body: Column(
        children: [
          const SizedBox(height: 35),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSettingsHeader(),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 35),
                    child: Column(
                      children: [
                        _buildSettingsTile(
                          context,
                          Icons.privacy_tip_outlined,
                          "Privacy Policy",
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const PrivacyPolicyScreen())),
                        ),
                        _buildSettingsTile(
                          context,
                          Icons.description_outlined,
                          "Terms and Conditions",
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const TermsScreen())),
                        ),
                        _buildSettingsTile(
                          context,
                          Icons.share_outlined,
                          "Share App",
                          onTap: () {
                            Share.share(
                                'Check out the Braita App! Download it here: https://play.google.com/store/apps/developer?id=Xendrio+App+Solutions');
                          },
                        ),
                        _buildSettingsTile(
                          context,
                          Icons.grid_view_rounded,
                          "More Apps",
                          onTap: () => _launchURL(
                              'https://play.google.com/store/apps/developer?id=Xendrio+App+Solutions'),
                        ),
                        _buildSettingsTile(
                          context,
                          Icons.developer_mode,
                          "About",
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const AboutScreen())),
                        ),
                        _buildSettingsTile(
                          context,
                          Icons.delete,
                          "Delete Account",
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  //builder: (context) => const AccountDeleteRequest())),
                            builder: (context) => const AccountDeleteRequest())),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Updated Tile Helper with BuildContext and onTap
  Widget _buildSettingsTile(BuildContext context, IconData icon, String title,
      {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF9C27B0),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9C27B0).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9C27B0),
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Color(0xFF9C27B0), size: 20),
          ],
        ),
      ),
    );
  }


  // --- Existing Header & Star Pattern Methods ---
  Widget _buildSettingsHeader() {
    return Container(
      margin: const EdgeInsets.all(10),
      height: 220,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF9C27B0),
        borderRadius: BorderRadius.all(Radius.circular(40)),
      ),
      child: Stack(
        children: [
          ..._buildFullStarPattern(rows: 3, columns: 4),
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Settings",
                    style: TextStyle(
                        fontSize: 48,
                        height: 0.7,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
                Text("Customize as you want",
                    style: TextStyle(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFullStarPattern(
      {required int rows, required int columns}) {
    List<Widget> stars = [];
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        stars.add(
          Positioned(
            top: (i * 90).toDouble() - 10,
            left: (j * 110).toDouble() - 10,
            child: Opacity(
              opacity: 0.3,
              child: Image.asset('Assets/Images/star2.png',
                  width: (i + j) % 2 == 0 ? 80 : 50,
                  height: (i + j) % 2 == 0 ? 80 : 50),
            ),
          ),
        );
      }
    }
    return stars;
  }
}
