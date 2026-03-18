import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

class InterstitialAdManager {
  // ANDROID ID
  final String _adUnitId = 'ca-app-pub-5065139330688835/4231561761';

  InterstitialAd? _interstitialAd;
  bool _isLoaded = false;

  // FIX: Added a public getter so QuizScreen can see if the ad is ready
  bool get isLoaded => _isLoaded;

  void loadAd() {
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoaded = true;
          debugPrint("✅ Interstitial Ad Loaded and Ready");
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isLoaded = false;
          _interstitialAd = null; // Good practice to nullify on failure
          debugPrint('❌ InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  void showAd({required Function onAdDismissed}) {
    if (_isLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isLoaded = false;
          _interstitialAd = null;
          loadAd(); // Load the next ad immediately
          onAdDismissed();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _isLoaded = false;
          _interstitialAd = null;
          loadAd(); // Reload even on failure
          onAdDismissed();
        },
      );
      _interstitialAd!.show();
    } else {
      debugPrint("⚠️ Ad not ready yet, navigating directly...");
      loadAd(); // Try loading again if it wasn't ready
      onAdDismissed();
    }
  }
}