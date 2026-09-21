import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/ad_units.dart';
import 'connectivity_service.dart';
import 'ad_state_provider.dart';

final adServiceProvider = Provider<AdService>((ref) {
  return AdService(ref);
});

class AdService {
  final Ref _ref;

  InterstitialAd? _qrCreateInterstitialAd;
  bool _isQrCreateInterstitialLoading = false;

  InterstitialAd? _scanInterstitialAd;
  bool _isScanInterstitialLoading = false;

  RewardedAd? _rewardedAd;
  bool _isRewardedLoading = false;

  static bool _isSdkInitialized = false;
  bool _isAdShowing = false;

  static const String _boxName = 'app_state';
  static const String _qrCreationCountKey = 'qrCreationCount';
  static const String _successfulScanCountKey = 'successfulScanCount';

  Future<int> _getCounter(String key) async {
    if (!Hive.isBoxOpen(_boxName)) await Hive.openBox(_boxName);
    final box = Hive.box(_boxName);
    return box.get(key, defaultValue: 0) as int;
  }

  Future<void> _incrementCounter(String key, int value) async {
    if (!Hive.isBoxOpen(_boxName)) await Hive.openBox(_boxName);
    final box = Hive.box(_boxName);
    await box.put(key, value);
  }

  AdService(this._ref) {
    if (_isSdkInitialized) {
      _preloadAllAds();
      // Ensure the provider state matches the static boolean if already initialized
      Future.microtask(() {
        _ref.read(adInitializationProvider.notifier).state = true;
      });
    } else {
      initializeConsentAndAds();
    }
  }

  void _preloadAllAds() {
    _preloadQrCreateInterstitial();
    _preloadScanInterstitial();
    _preloadRewarded();
  }

  /// Initialize MobileAds with UMP Consent
  Future<void> initializeConsentAndAds() async {
    log('AdService: SDK initialization started');
    final params = ConsentRequestParameters(
      consentDebugSettings: kDebugMode
          ? ConsentDebugSettings(
              debugGeography: DebugGeography.debugGeographyEea,
              testIdentifiers: ['TEST-DEVICE-HASH'], // In a real scenario, use actual test hash
            )
          : null,
    );

    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          if (await ConsentInformation.instance.isConsentFormAvailable()) {
            _loadConsentForm();
          } else {
            await _initializeAds();
          }
        },
        (FormError error) async {
          log('AdService: Consent Info Update failed: ${error.message}');
          await _initializeAds(); // fallback
        },
      );
    } catch (e) {
      log('AdService: Error during consent request: $e');
      await _initializeAds();
    }
  }

  void _loadConsentForm() {
    ConsentForm.loadConsentForm(
      (ConsentForm consentForm) async {
        final status = await ConsentInformation.instance.getConsentStatus();
        if (status == ConsentStatus.required) {
          consentForm.show(
            (FormError? formError) {
              if (formError != null) {
                log('AdService: Consent form show error: ${formError.message}');
              }
              _loadConsentForm();
            },
          );
        } else {
          await _initializeAds();
        }
      },
      (FormError formError) async {
        log('AdService: Consent form load error: ${formError.message}');
        await _initializeAds();
      },
    );
  }

  Future<void> _initializeAds() async {
    if (_isSdkInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _isSdkInitialized = true;
      log('AdService: SDK initialization completed');
      
      // Notify the rest of the app
      _ref.read(adInitializationProvider.notifier).state = true;
      
      // Preload ads immediately after initialization
      _preloadAllAds();
    } catch (e) {
      log('AdService: MobileAds initialization error: $e');
    }
  }

  bool _hasInternet() {
    final status = _ref.read(internetStatusProvider);
    return status == InternetStatus.connected;
  }

  void _preloadQrCreateInterstitial() {
    if (!_isSdkInitialized || _isQrCreateInterstitialLoading || _qrCreateInterstitialAd != null) return;

    _isQrCreateInterstitialLoading = true;
    log('AdService: QR Create Interstitial ad request started');

    InterstitialAd.load(
      adUnitId: AdUnits.qrCreateInterstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          log('AdService: QR Create Interstitial ad loaded');
          _qrCreateInterstitialAd = ad;
          _isQrCreateInterstitialLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          log('AdService: QR Create Interstitial ad failed to load: $error');
          _qrCreateInterstitialAd = null;
          _isQrCreateInterstitialLoading = false;
          // Note: we don't infinitely retry here to prevent spamming
        },
      ),
    );
  }

  void _preloadScanInterstitial() {
    if (!_isSdkInitialized || _isScanInterstitialLoading || _scanInterstitialAd != null) return;

    _isScanInterstitialLoading = true;
    log('AdService: Scan Interstitial ad request started');

    InterstitialAd.load(
      adUnitId: AdUnits.scanInterstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          log('AdService: Scan Interstitial ad loaded');
          _scanInterstitialAd = ad;
          _isScanInterstitialLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          log('AdService: Scan Interstitial ad failed to load: $error');
          _scanInterstitialAd = null;
          _isScanInterstitialLoading = false;
        },
      ),
    );
  }

  void _preloadRewarded() {
    if (!_isSdkInitialized || _isRewardedLoading || _rewardedAd != null) return;

    _isRewardedLoading = true;
    log('AdService: Rewarded ad request started');

    RewardedAd.load(
      adUnitId: AdUnits.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          log('AdService: Rewarded ad loaded');
          _rewardedAd = ad;
          _isRewardedLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          log('AdService: Rewarded ad failed to load: $error');
          _rewardedAd = null;
          _isRewardedLoading = false;
        },
      ),
    );
  }

  void _showQrCreateInterstitialIfAvailable(VoidCallback onContinue) {
    if (_isAdShowing || _qrCreateInterstitialAd == null || !_hasInternet() || !_isSdkInitialized) {
      log('AdService: QR Create Interstitial unavailable or cannot show (Showing: $_isAdShowing, Loaded: ${_qrCreateInterstitialAd != null}, Internet: ${_hasInternet()}, SDK: $_isSdkInitialized), proceeding.');
      onContinue();
      if (_qrCreateInterstitialAd == null) _preloadQrCreateInterstitial();
      return;
    }

    _isAdShowing = true;
    log('AdService: QR Create Interstitial ad show requested');

    _qrCreateInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        log('AdService: QR Create Interstitial ad show started (impression recorded)');
      },
      onAdClicked: (ad) {
        log('AdService: QR Create Interstitial ad clicked');
      },
      onAdDismissedFullScreenContent: (ad) {
        log('AdService: QR Create Interstitial ad dismissed');
        _isAdShowing = false;
        log('AdService: QR Create Interstitial ad object disposed');
        ad.dispose();
        _qrCreateInterstitialAd = null;
        onContinue();
        log('AdService: Next QR Create Interstitial ad preload started');
        _preloadQrCreateInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        log('AdService: QR Create Interstitial ad failed to show: $error');
        _isAdShowing = false;
        log('AdService: QR Create Interstitial ad object disposed');
        ad.dispose();
        _qrCreateInterstitialAd = null;
        onContinue();
        log('AdService: Next QR Create Interstitial ad preload started');
        _preloadQrCreateInterstitial();
      },
    );

    _qrCreateInterstitialAd!.show();
  }

  void _showScanInterstitialIfAvailable(VoidCallback onContinue) {
    if (_isAdShowing || _scanInterstitialAd == null || !_hasInternet() || !_isSdkInitialized) {
      log('AdService: Scan Interstitial unavailable or cannot show, proceeding.');
      onContinue();
      if (_scanInterstitialAd == null) _preloadScanInterstitial();
      return;
    }

    _isAdShowing = true;
    log('AdService: Scan Interstitial ad show requested');

    _scanInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        log('AdService: Scan Interstitial ad show started (impression recorded)');
      },
      onAdClicked: (ad) {
        log('AdService: Scan Interstitial ad clicked');
      },
      onAdDismissedFullScreenContent: (ad) {
        log('AdService: Scan Interstitial ad dismissed');
        _isAdShowing = false;
        log('AdService: Scan Interstitial ad object disposed');
        ad.dispose();
        _scanInterstitialAd = null;
        onContinue();
        log('AdService: Next Scan Interstitial ad preload started');
        _preloadScanInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        log('AdService: Scan Interstitial ad failed to show: $error');
        _isAdShowing = false;
        log('AdService: Scan Interstitial ad object disposed');
        ad.dispose();
        _scanInterstitialAd = null;
        onContinue();
        log('AdService: Next Scan Interstitial ad preload started');
        _preloadScanInterstitial();
      },
    );

    _scanInterstitialAd!.show();
  }

  void _showRewardedIfAvailable(VoidCallback onContinue) {
    if (_isAdShowing || _rewardedAd == null || !_hasInternet() || !_isSdkInitialized) {
      log('AdService: Rewarded unavailable or cannot show, proceeding.');
      onContinue();
      if (_rewardedAd == null) _preloadRewarded();
      return;
    }

    _isAdShowing = true;
    log('AdService: Rewarded ad show requested');

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        log('AdService: Rewarded ad show started (impression recorded)');
      },
      onAdClicked: (ad) {
        log('AdService: Rewarded ad clicked');
      },
      onAdDismissedFullScreenContent: (ad) {
        log('AdService: Rewarded ad dismissed');
        _isAdShowing = false;
        log('AdService: Rewarded ad object disposed');
        ad.dispose();
        _rewardedAd = null;
        onContinue();
        log('AdService: Next Rewarded ad preload started');
        _preloadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        log('AdService: Rewarded ad failed to show: $error');
        _isAdShowing = false;
        log('AdService: Rewarded ad object disposed');
        ad.dispose();
        _rewardedAd = null;
        onContinue();
        log('AdService: Next Rewarded ad preload started');
        _preloadRewarded();
      },
    );

    _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      log('AdService: User earned reward: ${reward.amount} ${reward.type}');
    });
  }
  
  Future<void> onSuccessfulCreate(VoidCallback onContinue) async {
    int count = await _getCounter(_qrCreationCountKey);
    count++;
    await _incrementCounter(_qrCreationCountKey, count);
    
    log('AdService: QR Create count: $count');
    
    if (count % 2 != 0) {
      _showQrCreateInterstitialIfAvailable(onContinue);
    } else {
      _showRewardedIfAvailable(onContinue);
    }
  }

  /// Called on successful scans. Will trigger rewarded every 2nd scan.
  Future<void> onSuccessfulScan(VoidCallback onContinue) async {
    int count = await _getCounter(_successfulScanCountKey);
    count++;
    await _incrementCounter(_successfulScanCountKey, count);
    
    log('AdService: Scan count: $count');
    
    if (count % 2 == 0) {
      _showRewardedIfAvailable(onContinue);
    } else {
      onContinue();
    }
  }

  BannerAd? createBannerAd(VoidCallback onLoaded, void Function(LoadAdError) onFailed) {
    if (!_isSdkInitialized || !_hasInternet()) {
      log('AdService: Banner creation skipped (Internet: ${_hasInternet()}, SDK: $_isSdkInitialized)');
      return null;
    }

    log('AdService: Banner ad request started');
    return BannerAd(
      adUnitId: AdUnits.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          log('AdService: Banner ad loaded');
          onLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          log('AdService: Banner ad failed to load: $error');
          log('AdService: Banner ad object disposed due to load failure');
          ad.dispose();
          onFailed(error);
        },
      ),
    )..load();
  }
}
