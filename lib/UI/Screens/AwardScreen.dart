import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../Ads/banner_ad_manager.dart';
import '../Widgets/BottomNavigationBar.dart';

class AwardScreen extends StatefulWidget {
  const AwardScreen({super.key});

  @override
  State<AwardScreen> createState() => _AwardScreenState();
}

class _AwardScreenState extends State<AwardScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('WinnersPosts');
  List<Map<String, String>> _winnersList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWinners();
  }

  void _fetchWinners() async {
    try {
      final event = await _dbRef.once();
      final snapshot = event.snapshot;

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, String>> tempWinners = [];

        // 1. Get all keys that start with 'Post'
        List<String> postKeys = data.keys
            .map((e) => e.toString())
            .where((key) => key.startsWith('Post'))
            .toList();

        // 2. Sort keys numerically descending (Post10, Post9, Post8...)
        postKeys.sort((a, b) {
          int idA = int.tryParse(a.replaceAll('Post', '')) ?? 0;
          int idB = int.tryParse(b.replaceAll('Post', '')) ?? 0;
          return idB.compareTo(idA); // Higher numbers first
        });

        // 3. Build the list using the sorted keys
        for (var key in postKeys) {
          String id = key.replaceAll('Post', '');
          String captionKey = 'Caption$id';

          tempWinners.add({
            'link': data[key].toString(),
            'caption': data[captionKey]?.toString() ?? 'Winner of Competition',
          });
        }

        if (mounted) {
          setState(() {
            _winnersList = tempWinners;
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("❌ Database Error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF9C27B0), // Braita Purple
      bottomNavigationBar: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MyBannerAdWidget(),

        ],
      ),
      body: Stack(
        children: [
          // 1. Background Star Pattern
          ..._buildFullStarPattern(rows: 10, columns: 4),

          // 2. Main Content
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                const Text(
                  "Winners",
                  style: TextStyle(
                      color: Colors.white,
                      height: 0.9,
                      fontSize: 50,
                      fontWeight: FontWeight.bold
                  ),
                ),
                const Text(
                  "of Competitions",
                  style: TextStyle(
                      color: Colors.white,
                      height: 0.6,
                      fontSize: 18
                  ),
                ),
                const SizedBox(height: 20),

                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : _winnersList.isEmpty
                      ? const Center(
                      child: Text(
                          "No winners found",
                          style: TextStyle(color: Colors.white)
                      )
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _winnersList.length,
                    itemBuilder: (context, index) {
                      return FBPostCard(
                        url: _winnersList[index]['link']!,
                        caption: _winnersList[index]['caption']!,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
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

  List<Widget> _buildFullStarPattern({required int rows, required int columns}) {
    List<Widget> stars = [];
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        stars.add(Positioned(
          top: (i * 150).toDouble(),
          left: (j * 120).toDouble() - 20,
          child: Opacity(
            opacity: 0.15,
            child: Image.asset(
                'Assets/Images/star2.png',
                width: (i + j) % 2 == 0 ? 100 : 70
            ),
          ),
        ));
      }
    }
    return stars;
  }
}

// --- MOBILE-OPTIMIZED FB POST WIDGET ---
class FBPostCard extends StatefulWidget {
  final String url;
  final String caption;
  const FBPostCard({super.key, required this.url, required this.caption});

  @override
  State<FBPostCard> createState() => _FBPostCardState();
}

class _FBPostCardState extends State<FBPostCard> {
  late final WebViewController _controller;
  bool _isWebLoading = true;

  @override
  void initState() {
    super.initState();

    // Convert to mobile-specific facebook link
    String mobileUrl = widget.url.replaceFirst('www.facebook.com', 'm.facebook.com');

    // Mobile-focused HTML code
    final String htmlContent = '''
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
          <style>
            body { margin: 0; padding: 0; background-color: white; overflow: hidden; }
            .fb-post { width: 100% !important; }
          </style>
        </head>
        <body>
          <div id="fb-root"></div>
          <script async defer crossorigin="anonymous" src="https://connect.facebook.net/en_US/sdk.js#xfbml=1&version=v17.0"></script>
          <div class="fb-post" data-href="$mobileUrl" data-width="auto" data-show-text="true"></div>
        </body>
      </html>
    ''';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) {
          if (mounted) setState(() => _isWebLoading = false);
        },
      ))
      ..loadHtmlString(htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 480, // Optimized height for mobile view
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8)
                )
              ],
            ),
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isWebLoading)
                  const Center(child: CircularProgressIndicator(color: Color(0xFF9C27B0))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              widget.caption,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- FIX FOR YOUR CODE ERROR: TrianglePainter ---
class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = Colors.white;
    var path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}