import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Scrolling Star Background
          SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(), // Keeps background fixed
            child: Column(
              children: _buildFullStarPattern(rows: 10, columns: 4),
            ),
          ),

          // 2. Main Content
          Column(
            children: [
              // Purple Header with Back Button
              _buildHeader(context),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      // --- App Logo Section ---
                      _buildLogoSection(),

                      const SizedBox(height: 20),
                      const Text(
                        "Braita",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF9C27B0)),
                      ),
                      const Text(
                        "Version 1.0.0",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),

                      const SizedBox(height: 40),

                      // --- App Purpose Section ---
                      _buildInfoSection(
                        title: "App Purpose",
                        content: "Braita is designed to enhance your learning through daily interactive quizzes. "
                            "Track your progress, compete with others in the Hero Ranking, and master new topics "
                            "with 20 fresh questions every day.",
                      ),

                      // --- Developer Information ---
                      _buildInfoSection(
                        title: "Developer Information",
                        content: "Developed and Maintained by:\nKITAAS SOLUTIONS",
                      ),

                      const SizedBox(height: 40),

                      // --- Footer ---
                      Image.asset('Assets/Images/developer.png', height: 50, width: 120),
                      const SizedBox(height: 10),
                      const Text(
                        "© 2026 KITAAS SOLUTIONS. All Rights Reserved.",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 120,
      padding: const EdgeInsets.only(top: 40, left: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF9C27B0),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(0), bottomRight: Radius.circular(0)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          const Text(
            "About Braita",
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Center(
      child: Container(
        width: 120, height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
          ],

        ),
        child: const Image(image: AssetImage('Assets/Images/robotimagetosplash.png')),
      ),
    );
  }

  Widget _buildInfoSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF635E64)),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: Color(0xFF757575), height: 1.5),
          ),
          const SizedBox(height: 15),
          const Divider(height: 1, thickness: 1, indent: 50, endIndent: 50),
        ],
      ),
    );
  }

  List<Widget> _buildFullStarPattern({required int rows, required int columns}) {
    List<Widget> stars = [];
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        stars.add(Positioned(
          top: (i * 120).toDouble() + 150,
          left: (j * 110).toDouble() - 10,
          child: Opacity(
            opacity: 0.1,
            child: Image.asset('Assets/Images/star2.png', width: (i + j) % 2 == 0 ? 80 : 50),
          ),
        ));
      }
    }
    return stars;
  }
}