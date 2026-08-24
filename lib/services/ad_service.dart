import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-9278969551746674/1875255183';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-9278969551746674/2934070461';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-9278969551746674/3109330288';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-9278969551746674/5035665792';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdLoading = false;

  static Future<void> init() async {
    await MobileAds.instance.initialize();
    loadInterstitialAd();
  }

  static void loadInterstitialAd() {
    if (_isInterstitialAdLoading) return;
    _isInterstitialAdLoading = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
          _isInterstitialAdLoading = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  static Future<void> showInterstitialAd({required VoidCallback onAdDismissed}) async {
    if (_interstitialAd == null) {
      debugPrint('Warning: InterstitialAd is null, proceeding with action');
      onAdDismissed();
      loadInterstitialAd();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadInterstitialAd();
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        loadInterstitialAd();
        onAdDismissed();
      },
    );

    await _interstitialAd!.show();
    _interstitialAd = null;
  }
}
