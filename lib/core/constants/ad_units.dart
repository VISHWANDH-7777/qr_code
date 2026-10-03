import 'dart:io';


/// AdMob ad unit ids used by the app.
///
/// An ad unit id looks like `ca-app-pub-XXXXXXXXXXXXXXXX/NNNNNNNNNN`.
/// The AdMob **app id** looks the same but with a `~` instead of `/` and is
/// configured in `android/app/src/main/AndroidManifest.xml`.
///
/// Ad units required by the app (create them in AdMob > Apps > your app >
/// Ad units):
///   * banner               - above the bottom navigation bar, on every tab
///   * qrCreateInterstitial - after every 2nd QR code is created
///   * scanInterstitial     - after every 2nd successful scan
///   * rewarded             - opt-in only, see `AdService.showRewardedAd`
///
/// Any unit you have not created yet can keep the Google test id below, the app
/// still works (it simply serves test ads for that format).
class AdUnits {
  // Set this to false ONLY when building the final release for Google Play.
  // Google AdMob does not serve real ads to unpublished apps or locally tested APKs.
  // Using test ads ensures you can verify ad formats in both debug and release APKs.
  static const bool useTestAds = false;

  // Google Official Test Ad Unit IDs
  static const String _androidTestBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const String _androidTestInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const String _androidTestRewarded = 'ca-app-pub-3940256099942544/5224354917';

  // Your Production Ad Unit IDs
  static const String _androidBannerProduction = 'ca-app-pub-2870397787356017/1991154306';
  static const String _androidQrCreateInterstitialProduction = 'ca-app-pub-2870397787356017/4481586279';
  static const String _androidScanInterstitialProduction = 'ca-app-pub-2870397787356017/4481586279';
  static const String _androidRewardedProduction = 'ca-app-pub-2870397787356017/5351281989';

  static String get banner {
    if (Platform.isAndroid) {
      return useTestAds ? _androidTestBanner : _androidBannerProduction;
    }
    if (Platform.isIOS) {
      throw UnsupportedError('Production Ad Unit ID missing for iOS banner.');
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get qrCreateInterstitial {
    if (Platform.isAndroid) {
      return useTestAds ? _androidTestInterstitial : _androidQrCreateInterstitialProduction;
    }
    if (Platform.isIOS) {
      throw UnsupportedError('Production Ad Unit ID missing for iOS QR Creation Interstitial.');
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get scanInterstitial {
    if (Platform.isAndroid) {
      return useTestAds ? _androidTestInterstitial : _androidScanInterstitialProduction;
    }
    if (Platform.isIOS) {
      throw UnsupportedError('Production Ad Unit ID missing for iOS Scan Interstitial.');
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get rewarded {
    if (Platform.isAndroid) {
      return useTestAds ? _androidTestRewarded : _androidRewardedProduction;
    }
    if (Platform.isIOS) {
      throw UnsupportedError('Production Ad Unit ID missing for iOS Rewarded.');
    }
    throw UnsupportedError('Unsupported platform');
  }
}
