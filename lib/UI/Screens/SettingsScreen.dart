import 'package:braita_new/UI/Screens/AboutScreen.dart';
import 'package:braita_new/UI/Screens/AvatarSelectScreen.dart';
import 'package:braita_new/UI/Screens/HomeScreen.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:braita_new/Services/DatabaseService.dart';
import '../../Ads/banner_ad_manager.dart';
import '../Widgets/BottomNavigationBar.dart';
import 'AccountDeleteRequest.dart';
import 'PrivacyPolicyScreen.dart';
import 'TermsScreen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
      bottomNavigationBar: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MyBannerAdWidget(),
          BottomNavigation(currentIndex: 3),
        ],
      ),
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
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen())),
                        ),
                        _buildSettingsTile(
                          context,
                          Icons.description_outlined,
                          "Terms and Conditions",
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsScreen())),
                        ),
                        _buildSettingsTile(
                          context,
                          Icons.share_outlined,
                          "Share App",
                          onTap: () => Share.share('Check out the Braita App! https://play.google.com/store/apps/developer?id=Xendrio+App+Solutions'),
                        ),
                        _buildSettingsTile(
                          context,
                          Icons.grid_view_rounded,
                          "More Apps",
                          onTap: () => _launchURL('https://play.google.com/store/apps/developer?id=Xendrio+App+Solutions'),
                        ),
                        _buildSettingsTile(
                          context,
                          Icons.developer_mode,
                          "About",
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen())),
                        ),
                        _buildSettingsTile(
                          context,
                          Icons.history_rounded,
                          "Recover Account",
                          onTap: () => _showRecoverDialog(context),
                        ),
                        _buildSettingsTile(
                          context,
                          Icons.delete,
                          "Delete Account",
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountDeleteRequest())),
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

  void _showRecoverDialog(BuildContext context) async {
    final TextEditingController acController = TextEditingController();
    final TextEditingController pinController = TextEditingController();
    final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
    final DatabaseService dbService = DatabaseService();
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Define the style for the individual PIN boxes to match the previous dialog
    final defaultPinTheme = PinTheme(
      width: 45,
      height: 55,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[300], // Matching your TextField fill color
        borderRadius: BorderRadius.circular(10),
      ),
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            // --- COUNTDOWN CALCULATION ---
            int fails = prefs.getInt('recovery_fails') ?? 0;
            int lastFailTime = prefs.getInt('last_fail_timestamp') ?? 0;
            int currentTime = DateTime.now().millisecondsSinceEpoch;
            int lockDuration = 1800000; // 30 Minutes

            int timeLeftMs = lockDuration - (currentTime - lastFailTime);
            bool isLocked = (fails >= 5) && (timeLeftMs > 0);

            // Format milliseconds to MM:SS
            String formatTime(int ms) {
              int seconds = (ms / 1000).truncate();
              int minutes = (seconds / 60).truncate();
              String minutesStr = (minutes % 60).toString().padLeft(2, '0');
              String secondsStr = (seconds % 60).toString().padLeft(2, '0');
              return "$minutesStr:$secondsStr";
            }

            // Start a timer that refreshes the dialog every second if locked
            if (isLocked) {
              Future.delayed(const Duration(seconds: 1), () {
                if (context.mounted) setState(() {});
              });
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: const BoxDecoration(color: Color(0xFF9C27B0), borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
                      child: const Text("Recover Account", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          if (isLocked) ...[
                            const Icon(Icons.lock_clock_rounded, color: Colors.red, size: 50),
                            const SizedBox(height: 10),
                            const Text("Too many failed attempts!", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            Text("Try again in ${formatTime(timeLeftMs)}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 20),
                          ] else ...[
                            const Text("Enter account number", style: TextStyle(fontWeight: FontWeight.bold)),
                            const Text("ගිණුම් අංකය ඇතුලත් කරන්න", style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 5),
                            TextField(
                                controller: acController,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                    fillColor: Colors.grey[300],
                                    filled: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)
                                )
                            ),
                            const SizedBox(height: 15),
                            const Text("Enter Pin number", style: TextStyle(fontWeight: FontWeight.bold)),
                            const Text("පින් අංකය ඇතුලත් කරන්න", style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 10),

                            // --- UPDATED PIN FIELD ---
                            Pinput(
                              length: 5,
                              controller: pinController,
                              keyboardType: TextInputType.number,
                              obscureText: true, // PIN remains hidden
                              defaultPinTheme: defaultPinTheme,
                              focusedPinTheme: defaultPinTheme.copyWith(
                                decoration: defaultPinTheme.decoration!.copyWith(
                                  border: Border.all(color: const Color(0xFF9C27B0), width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          ElevatedButton(
                            onPressed: isLocked ? null : () async {
                              String inputTag = acController.text.trim();
                              String inputPin = pinController.text.trim();
                              String currentTempId = await dbService.getDeviceId();
                              String sanitizedTempId = currentTempId.replaceAll(RegExp(r'[.#$\[\]]'), '_');

                              final snapshot = await dbRef.child('User').orderByChild('UserTag').equalTo(inputTag).get();

                              if (snapshot.exists) {
                                Map users = snapshot.value as Map;
                                String foundOldDeviceId = users.keys.first;
                                Map userData = users[foundOldDeviceId];

                                if (userData['Pin'].toString() == inputPin) {
                                  await prefs.setInt('recovery_fails', 0);
                                  await dbService.updateDeviceId(foundOldDeviceId);
                                  if (foundOldDeviceId != sanitizedTempId) {
                                    await dbRef.child('User').child(sanitizedTempId).remove();
                                  }
                                  Navigator.pop(context);
                                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false);
                                } else {
                                  int newFails = (prefs.getInt('recovery_fails') ?? 0) + 1;
                                  await prefs.setInt('recovery_fails', newFails);
                                  await prefs.setInt('last_fail_timestamp', DateTime.now().millisecondsSinceEpoch);
                                  setState(() {}); // Refresh UI for wrong pin
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account Number not found")));
                              }
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: isLocked ? Colors.grey : const Color(0xFF9C27B0),
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))
                            ),
                            child: Text(isLocked ? "Locked" : "Recover", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFAFA9B0),
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))
                              ),
                              child: const Text("Cancel", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, IconData icon, String title, {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        onTap: onTap,
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF9C27B0), shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFF9C27B0).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]), child: Icon(icon, color: Colors.white, size: 24)),
          const SizedBox(width: 20),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF9C27B0)))),
          const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF9C27B0), size: 20),
        ]),
      ),
    );
  }

  Widget _buildSettingsHeader() {
    return Container(
      margin: const EdgeInsets.all(10), height: 220, width: double.infinity,
      decoration: const BoxDecoration(color: Color(0xFF9C27B0), borderRadius: BorderRadius.all(Radius.circular(40))),
      child: Stack(children: [
        ..._buildFullStarPattern(rows: 3, columns: 4),
        const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text("Settings", style: TextStyle(fontSize: 48, height: 0.7, fontWeight: FontWeight.w900, color: Colors.white)), Text("Customize as you want", style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.white))])),
      ]),
    );
  }

  List<Widget> _buildFullStarPattern({required int rows, required int columns}) {
    List<Widget> stars = [];
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        stars.add(Positioned(top: (i * 90).toDouble() - 10, left: (j * 110).toDouble() - 10, child: Opacity(opacity: 0.3, child: Image.asset('Assets/Images/star2.png', width: (i + j) % 2 == 0 ? 80 : 50, height: (i + j) % 2 == 0 ? 80 : 50))));
      }
    }
    return stars;
  }
}//correct