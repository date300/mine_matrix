import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  static InterstitialAd? interstitialAd;

  static void loadInterstitial() {
    InterstitialAd.load(
      adUnitId: "ca-app-pub-9354625065393218/3977151520",
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          interstitialAd = null;
        },
      ),
    );
  }

  static void showInterstitial() {
    if (interstitialAd == null) return;

    interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        interstitialAd = null;
        loadInterstitial(); // dismiss হওয়ার পর reload
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        interstitialAd = null;
        loadInterstitial();
      },
    );

    interstitialAd!.show();
  }
}
