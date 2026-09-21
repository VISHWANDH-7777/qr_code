import 'dart:io';
import 'package:flutter/foundation.dart';

class AdUnits {
  static String get banner {
    if (kReleaseMode) {
      if (Platform.isAndroid) return 'ca-app-pub-2870397787356017/1991154306';
      // Fallback for iOS if not provided, assuming android only for now or using test
      if (Platform.isIOS) return 'ca-app-pub-3940256099942544/2934735716';
      throw UnsupportedError('Unsupported platform');
    } else {
      // Test Ad Unit IDs
      if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/6300978111';
      if (Platform.isIOS) return 'ca-app-pub-3940256099942544/2934735716';
      throw UnsupportedError('Unsupported platform');
    }
  }

  // TODO: A separate QR Creation Interstitial ID can be assigned later without changing AdService logic.
  static String get qrCreateInterstitial {
    if (kReleaseMode) {
      if (Platform.isAndroid) return 'ca-app-pub-2870397787356017/4481586279';
      if (Platform.isIOS) return 'ca-app-pub-3940256099942544/4411468910';
      throw UnsupportedError('Unsupported platform');
    } else {
      if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/1033173712';
      if (Platform.isIOS) return 'ca-app-pub-3940256099942544/4411468910';
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get scanInterstitial {
    if (kReleaseMode) {
      if (Platform.isAndroid) return 'ca-app-pub-2870397787356017/4481586279';
      if (Platform.isIOS) return 'ca-app-pub-3940256099942544/4411468910';
      throw UnsupportedError('Unsupported platform');
    } else {
      if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/1033173712';
      if (Platform.isIOS) return 'ca-app-pub-3940256099942544/4411468910';
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get rewarded {
    if (kReleaseMode) {
      if (Platform.isAndroid) return 'ca-app-pub-2870397787356017/5351281989';
      if (Platform.isIOS) return 'ca-app-pub-3940256099942544/1712480170';
      throw UnsupportedError('Unsupported platform');
    } else {
      if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/5224354917';
      if (Platform.isIOS) return 'ca-app-pub-3940256099942544/1712480170';
      throw UnsupportedError('Unsupported platform');
    }
  }
}
