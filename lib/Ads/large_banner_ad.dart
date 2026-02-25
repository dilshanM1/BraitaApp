import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class LargeBannerAd extends StatefulWidget {
  const LargeBannerAd({super.key});

  @override
  State<LargeBannerAd> createState() => _LargeBannerAdState();
}

class _LargeBannerAdState extends State<LargeBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  // Android Test ID for Banner
  final String _adUnitId = 'ca-app-pub-5065139330688835/3053776694';

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      // Medium Rectangle (300x250) is the "little bit larger" format
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Medium Rectangle failed to load: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(vertical: 10),
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        // Adding a slight decoration to make it look premium in your app
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: AdWidget(ad: _bannerAd!),
        ),
      );
    }
    // Return a small gap while loading so the UI doesn't look empty
    return const SizedBox(height: 20);
  }
}