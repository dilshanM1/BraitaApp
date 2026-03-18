import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../Ads/banner_ad_manager.dart';


class GuideVideoScreen extends StatefulWidget {
  const GuideVideoScreen({super.key});

  @override
  State<GuideVideoScreen> createState() => _GuideVideoScreenState();
}

class _GuideVideoScreenState extends State<GuideVideoScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  List<Map<String, String>> _guideVideos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  void _fetchVideos() async {
    try {
      final event = await _dbRef.child('GuideVideos').once();
      final snapshot = event.snapshot;

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, String>> tempVideos = [];

        data.forEach((key, value) {
          if (key.toString().startsWith('Video') && !key.toString().contains('Title')) {
            String id = key.toString().replaceAll('Video', '');
            String titleKey = 'Video${id}Title';

            tempVideos.add({
              'url': value.toString(),
              'title': data[titleKey]?.toString() ?? 'Watch Guide',
            });
          }
        });

        if (mounted) {
          setState(() {
            _guideVideos = tempVideos;
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("❌ Error fetching videos: $e");
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

        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 35),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildGuideHeader(context),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF9C27B0)))
                      : _guideVideos.isEmpty
                      ? const Center(child: Text("No videos found"))
                      : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.builder(
                      shrinkWrap: true, // Needed inside SingleChildScrollView
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 20,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _guideVideos.length,
                      itemBuilder: (context, index) {
                        return VideoCard(
                          url: _guideVideos[index]['url']!,
                          title: _guideVideos[index]['title']!,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideHeader(BuildContext context) {
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
          // Back Button
          Positioned(
            top: 20,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const CircleAvatar(
                backgroundColor: Colors.white,
                radius: 18,
                child: Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF9C27B0), size: 18),
              ),
            ),
          ),
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Guide",
                    style: TextStyle(
                        fontSize: 55,
                        height: 0.7,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
                Text("To use app",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ],
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

class VideoCard extends StatelessWidget {
  final String url;
  final String title;
  const VideoCard({super.key, required this.url, required this.title});

  @override
  Widget build(BuildContext context) {
    String? videoId = YoutubePlayer.convertUrlToId(url);

    return GestureDetector(
      onTap: () {
        if (videoId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(videoId: videoId),
            ),
          );
        }
      },
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                ],
                image: videoId != null
                    ? DecorationImage(
                  image: NetworkImage("https://img.youtube.com/vi/$videoId/mqdefault.jpg"),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: const Center(
                child: Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF635E64)
            ),
          ),
        ],
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  const VideoPlayerScreen({super.key, required this.videoId});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: const Color(0xFF9C27B0),
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
              backgroundColor: Colors.transparent,
              iconTheme: const IconThemeData(color: Colors.white)
          ),
          body: Center(child: player),
        );
      },
    );
  }
}