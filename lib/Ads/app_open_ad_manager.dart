import 'package:google_mobile_ads/google_mobile_ads.dart';

class AppOpenAdManager {
  // ANDROID TEST ID: Replace this with your REAL Android Ad Unit ID later
  final String _adUnitId = 'ca-app-pub-5065139330688835/5600048989';

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  bool isAdAvailable = false;

  /// Loads the ad during splash
  void loadAd({required Function() onAdLoaded}) {
    AppOpenAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          isAdAvailable = true;
          onAdLoaded(); // Notify Splash Screen immediately
        },
        onAdFailedToLoad: (error) {
          print('AppOpenAd failed to load: $error');
          isAdAvailable = false;
          onAdLoaded(); // Proceed to Home even if load fails
        },
      ),
    );
  }

  /// Shows the ad and triggers the callback when finished
  void showAdIfAvailable(Function onAdDismissed) {
    if (!isAdAvailable || _appOpenAd == null) {
      onAdDismissed(); // Move to home if ad isn't ready
      return;
    }

    if (_isShowingAd) return;

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        isAdAvailable = false;
        ad.dispose();
        onAdDismissed(); // Proceed to HomeScreen
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        isAdAvailable = false;
        ad.dispose();
        onAdDismissed(); // Proceed even if ad fails
      },
    );

    _appOpenAd!.show();
  }
}