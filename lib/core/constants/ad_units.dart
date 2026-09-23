import 'dart:io';
import 'package:flutter/foundation.dart';

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
  /// When `true` the production ad units below are also requested in debug
  /// builds (instead of Google's test units), so the real ad units can be
  /// verified while running `flutter run -d <device>`.
  ///
  /// WARNING: clicking your own live ads is invalid traffic and can get the
  /// AdMob account suspended. For safe testing either register this device in
  /// AdMob > Settings > Test devices (and add its id to
  /// `AdService.debugTestDeviceIds`), or set this flag back to `false` and use a
  /// release build (`flutter run --release -d <device>`) with real devices/users.
  static const bool useRealAdUnitsInDebug = true;

  static const String _androidBannerProduction = 'ca-app-pub-2870397787356017/1991154306';
  static const String _androidQrCreateInterstitialProduction = 'ca-app-pub-2870397787356017/4481586279';
  // TODO: create a dedicated "scan interstitial" unit in AdMob and paste it
  // here. Until then the QR creation unit is reused (allowed, but it merges the
  // reporting of both placements).
  static const String _androidScanInterstitialProduction = 'ca-app-pub-2870397787356017/4481586279';
  static const String _androidRewardedProduction = 'ca-app-pub-2870397787356017/5351281989';

  // Google's official sample (test) units.
  static const String _androidBannerTest = 'ca-app-pub-3940256099942544/6300978111';
  static const String _androidInterstitialTest = 'ca-app-pub-3940256099942544/1033173712';
  static const String _androidRewardedTest = 'ca-app-pub-3940256099942544/5224354917';
  static const String _iosBannerTest = 'ca-app-pub-3940256099942544/2934735716';
  static const String _iosInterstitialTest = 'ca-app-pub-3940256099942544/4411468910';
  static const String _iosRewardedTest = 'ca-app-pub-3940256099942544/1712480170';

  /// True when the production ad units should be used.
  static bool get _useProductionUnits => kReleaseMode || useRealAdUnitsInDebug;

  static String get banner {
    if (Platform.isAndroid) {
      return _useProductionUnits ? _androidBannerProduction : _androidBannerTest;
    }
    if (Platform.isIOS) {
      // TODO: add the production iOS banner unit when iOS builds are released.
      return _iosBannerTest;
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get qrCreateInterstitial {
    if (Platform.isAndroid) {
      return _useProductionUnits ? _androidQrCreateInterstitialProduction : _androidInterstitialTest;
    }
    if (Platform.isIOS) {
      // TODO: add the production iOS interstitial unit when iOS builds are released.
      return _iosInterstitialTest;
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get scanInterstitial {
    if (Platform.isAndroid) {
      return _useProductionUnits ? _androidScanInterstitialProduction : _androidInterstitialTest;
    }
    if (Platform.isIOS) {
      // TODO: add the production iOS interstitial unit when iOS builds are released.
      return _iosInterstitialTest;
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get rewarded {
    if (Platform.isAndroid) {
      return _useProductionUnits ? _androidRewardedProduction : _androidRewardedTest;
    }
    if (Platform.isIOS) {
      // TODO: add the production iOS rewarded unit when iOS builds are released.
      return _iosRewardedTest;
    }
    throw UnsupportedError('Unsupported platform');
  }
}
