import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PastpapersScreen extends StatefulWidget {
  const PastpapersScreen({super.key});

  @override
  State<PastpapersScreen> createState() => _PastpapersScreenState();
}

class _PastpapersScreenState extends State<PastpapersScreen> {
  late final WebViewController controller;
  bool isLoading = true; // State variable to control the spinner

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            // Start showing the spinner when the page begins loading
            setState(() {
              isLoading = true;
            });
          },
          onPageFinished: (String url) {
            // Stop showing the spinner once the page is fully loaded
            setState(() {
              isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
            // Also stop loading if there is an error
            setState(() {
              isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(
          'https://www.doenets.lk/pastpapers'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 35),
          // 1. Header Section
          _buildHeader(context, "Past Papers", "Collect from below"),

          // 2. WebView Section with Spinner logic
          Expanded(
            child: Stack(
              children: [
                // The actual website content
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: WebViewWidget(controller: controller),
                ),

                // 3. Conditional Spinner: Only shows when isLoading is true
                if (isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF9C27B0),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // --- Header Widget ---
  Widget _buildHeader(BuildContext context, String title, String subTitle) {
    return Container(
      margin: const EdgeInsets.all(10),
      height: 200,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF9C27B0),
        borderRadius: BorderRadius.all(Radius.circular(40)),
      ),
      child: Stack(
        children: [
          ..._buildFullStarPattern(rows: 3, columns: 4),

          // Back Button
          Positioned(
            top: 20,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_rounded,
                    color: Color(0xFF9C27B0), size: 20),
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 0.7,
                      color: Colors.white),
                ),
                Text(
                  subTitle,
                  style: const TextStyle(
                      fontSize: 18,
                      height: 1,
                      fontStyle: FontStyle.italic,
                      color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Star Pattern Helper ---
  List<Widget> _buildFullStarPattern({required int rows, required int columns}) {
    List<Widget> stars = [];
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        stars.add(
          Positioned(
            top: (i * 90).toDouble() - 10,
            left: (j * 110).toDouble() - 10,
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                'Assets/Images/star2.png',
                width: (i + j) % 2 == 0 ? 80 : 50,
                height: (i + j) % 2 == 0 ? 80 : 50,
              ),
            ),
          ),
        );
      }
    }
    return stars;
  }
}