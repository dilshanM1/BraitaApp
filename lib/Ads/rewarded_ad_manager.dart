import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

class RewardedAdManager {
  RewardedAd? _rewardedAd;
  bool isLoaded = false;

  // Use Test ID for development
  final String adUnitId = 'ca-app-pub-5065139330688835/8021373785';

  // In lib/Ads/rewarded_ad_manager.dart

  void loadAd({VoidCallback? onAdLoaded}) { // Add a callback parameter
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          isLoaded = true;
          onAdLoaded?.call(); // Notify the UI that loading is done
        },
        onAdFailedToLoad: (error) {
          isLoaded = false;
          debugPrint('RewardedAd failed to load: $error');
        },
      ),
    );
  }

  void showAd({required Function onRewardEarned}) {
    if (isLoaded && _rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          loadAd(); // Preload the next one
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          loadAd();
        },
      );

      _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
        onRewardEarned(); // This triggers the 2 points logic
      });
    } else {
      debugPrint('Ad not ready yet');
    }
  }
}