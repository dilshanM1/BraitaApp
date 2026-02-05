import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // Aligns title to the left near the back arrow
        centerTitle: false,
        title: const Text(
            "About Braita",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        backgroundColor: const Color(0xFF9C27B0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // --- App Logo Section ---
            Center(
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF9C27B0), width: 2),
                ),
                child: const Icon(Icons.school_rounded, size: 60, color: Color(0xFF9C27B0)),
              ),
            ),

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

            // --- App Purpose Section (Centered Content) ---
            _buildInfoSection(
              title: "App Purpose",
              content: "Braita is designed to enhance your learning through daily interactive quizzes. "
                  "Track your progress, compete with others in the Hero Ranking, and master new topics "
                  "with 20 fresh questions every day.",
              isCenter: true,
            ),

            // --- Developer Information (Centered Content) ---
            _buildInfoSection(
              title: "Developer Information",
              content: "Developed and Maintained by:\nKITAAS SOLUTIONS",
              isCenter: true,
            ),

            const SizedBox(height: 50),

            const Text(
              "© 2026 KITAAS SOLUTIONS. All Rights Reserved.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- Helper Widget ---
  Widget _buildInfoSection({required String title, required String content, bool isCenter = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      child: Column(
        crossAxisAlignment: isCenter ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(
            title,
            textAlign: isCenter ? TextAlign.center : TextAlign.start,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF635E64)),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            textAlign: isCenter ? TextAlign.center : TextAlign.start,
            style: const TextStyle(fontSize: 15, color: Color(0xFF757575), height: 1.5),
          ),
          const Divider(height: 30, thickness: 1),
        ],
      ),
    );
  }
}