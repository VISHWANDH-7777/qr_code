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

  Timer? _consentFallbackTimer;
  int _consentCheckAttempts = 0;

  /// How long to wait between consent state re-checks while the UMP callbacks
  /// have not produced a usable consent state yet.
  static const Duration _consentRecheckDelay = Duration(seconds: 5);

  /// Maximum number of consent state re-checks before giving up (ads stay
  /// disabled, which is the correct behaviour when consent is required).
  static const int _maxConsentCheckAttempts = 12;

  /// Device ids (added in AdMob > Settings > Test devices) that should always
  /// receive test ads. Leave empty to disable test device configuration.
  /// These are only applied in debug builds.
  static const List<String> debugTestDeviceIds = <String>[];

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
      _markSdkInitialized();
    } else {
      initializeConsentAndAds();
    }
  }

  /// Whether the Mobile Ads SDK has finished initializing. Ads can only be
  /// created after this returns true.
  bool get isSdkReady => _isSdkInitialized;

  /// Notifies the UI that the SDK is ready so banners/Hive backed widgets can
  /// start requesting ads.
  ///
  /// Riverpod does not allow a provider to change the state of another provider
  /// while it is being created, therefore this is deferred to the next
  /// microtask.
  void _markSdkInitialized() {
    Future.microtask(() {
      if (!_ref.read(adInitializationProvider)) {
        _ref.read(adInitializationProvider.notifier).state = true;
      }
    });
  }

  void _preloadAllAds() {
    _preloadQrCreateInterstitial();
    _preloadScanInterstitial();
    _preloadRewarded();
  }

  /// Initializes the UMP consent flow and, once consent allows it, the Mobile
  /// Ads SDK.
  ///
  /// The UMP callbacks are not guaranteed to fire on every device, so a
  /// periodic re-check of `canRequestAds()` acts as a safety net. Without it the
  /// SDK could stay uninitialized forever and no ad would ever be requested.
  Future<void> initializeConsentAndAds() async {
    log('AdService: SDK initialization started');

    // Configure test devices (debug only) before any ad request is made.
    if (kDebugMode && debugTestDeviceIds.isNotEmpty) {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: debugTestDeviceIds),
      );
      log('AdService: test devices configured: ${debugTestDeviceIds.join(', ')}');
    }

    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        _consentRequestParameters(),
        () async {
          log('AdService: Consent info update succeeded');
          await _continueAfterConsentUpdate();
        },
        (FormError error) async {
          log('AdService: Consent info update failed: ${error.message}');
          await _continueAfterConsentUpdate();
        },
      );
    } catch (e) {
      log('AdService: Error during consent request: $e');
      await _continueAfterConsentUpdate();
    }

    // Safety net: keep re-checking the consent state in case none of the
    // callbacks above ever runs.
    _scheduleConsentRecheck();
  }

  ConsentRequestParameters _consentRequestParameters() {
    if (!kDebugMode || debugTestDeviceIds.isEmpty) {
      return ConsentRequestParameters();
    }
    return ConsentRequestParameters(
      consentDebugSettings: ConsentDebugSettings(
        debugGeography: DebugGeography.debugGeographyEea,
        testIdentifiers: debugTestDeviceIds,
      ),
    );
  }

  /// True when the UMP SDK reports that ads may be requested (consent is either
  /// not required or has already been obtained).
  Future<bool> _canRequestAds() async {
    try {
      if (await ConsentInformation.instance.canRequestAds()) return true;
      final status = await ConsentInformation.instance.getConsentStatus();
      return status == ConsentStatus.notRequired || status == ConsentStatus.obtained;
    } catch (e) {
      log('AdService: Consent status check failed: $e');
      return false;
    }
  }

  Future<void> _continueAfterConsentUpdate() async {
    if (_isSdkInitialized) return;

    if (await _canRequestAds()) {
      log('AdService: Consent allows ad requests, initializing SDK');
      await _initializeAds();
      return;
    }

    if (await ConsentInformation.instance.isConsentFormAvailable()) {
      log('AdService: Consent required, showing consent form');
      _loadConsentForm();
      return;
    }

    log('AdService: Consent required but no form available, waiting for consent');
  }

  void _scheduleConsentRecheck() {
    _consentFallbackTimer?.cancel();
    _consentFallbackTimer = Timer(_consentRecheckDelay, () async {
      if (_isSdkInitialized) return;

      if (await _canRequestAds()) {
        log('AdService: Consent allows ad requests (recheck), initializing SDK');
        await _initializeAds();
        return;
      }

      if (_consentCheckAttempts++ < _maxConsentCheckAttempts) {
        _scheduleConsentRecheck();
      } else {
        log('AdService: Consent still not granted after rechecks, ads stay disabled');
      }
    });
  }

  void _loadConsentForm() {
    ConsentForm.loadConsentForm(
      (ConsentForm consentForm) async {
        final status = await ConsentInformation.instance.getConsentStatus();
        if (status == ConsentStatus.required) {
          consentForm.show(
            (FormError? formError) async {
              if (formError != null) {
                log('AdService: Consent form show error: ${formError.message}');
              }
              // Re-evaluate after the form is dismissed instead of showing it
              // again (the previous code re-entered this method and could loop
              // forever when the user dismissed the form).
              await _continueAfterConsentUpdate();
            },
          );
        } else {
          await _continueAfterConsentUpdate();
        }
      },
      (FormError formError) async {
        log('AdService: Consent form load error: ${formError.message}');
        await _continueAfterConsentUpdate();
      },
    );
  }

  Future<void> _initializeAds() async {
    if (_isSdkInitialized) return;
    _consentFallbackTimer?.cancel();
    try {
      await MobileAds.instance.initialize();
      _isSdkInitialized = true;
      log('AdService: SDK initialization completed');

      // Notify the rest of the app so widgets can request their ads.
      _markSdkInitialized();

      // Preload ads immediately after initialization
      _preloadAllAds();
    } catch (e) {
      log('AdService: MobileAds initialization error: $e');
      // Initialization can fail when the device is offline or while Play services
      // are updating, so keep retrying for a while instead of leaving the app
      // without ads for the rest of the session.
      if (_consentCheckAttempts++ < _maxConsentCheckAttempts) {
        log('AdService: retrying SDK initialization in ${_consentRecheckDelay.inSeconds}s');
        _scheduleConsentRecheck();
      } else {
        log('AdService: SDK initialization retries exhausted');
      }
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

  /// Preloads the QR creation interstitial so it is ready for the next QR
  /// generation. Safe to call multiple times, the service guards against
  /// duplicate requests.
  void preloadQrCreateInterstitialAd() {
    _preloadQrCreateInterstitial();
  }

  /// Shows a rewarded ad. Rewarded ads are **opt-in only** according to AdMob
  /// policy, so this must be triggered from an explicit user action (for example
  /// a "Watch an ad to unlock" button) and never automatically after a scan or a
  /// QR creation. [onContinue] runs in every code path.
  void showRewardedAd(VoidCallback onContinue) {
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
  
  /// Called after a QR code was created. Shows the QR creation interstitial on
  /// every generation, then runs [onContinue] (navigation to the preview).
  ///
  /// Note: [onContinue] always runs, even when no ad is loaded, so the user is
  /// never blocked.
  Future<void> onSuccessfulCreate(VoidCallback onContinue) async {
    final int count = await _getCounter(_qrCreationCountKey) + 1;
    await _incrementCounter(_qrCreationCountKey, count);

    log('AdService: QR Create count: $count');

    _showQrCreateInterstitialIfAvailable(onContinue);
  }

  /// Called after a successful scan. Shows the scan interstitial ad on every
  /// second scan to stay within AdMob's interstitial frequency rules.
  Future<void> onSuccessfulScan(VoidCallback onContinue) async {
    int count = await _getCounter(_successfulScanCountKey);
    count++;
    await _incrementCounter(_successfulScanCountKey, count);
    
    log('AdService: Scan count: $count');
    
    if (count % 2 == 0) {
      _showScanInterstitialIfAvailable(onContinue);
    } else {
      onContinue();
    }
  }

  /// Creates and loads a banner ad.
  ///
  /// Returns `null` when the SDK is not ready or the device is offline; callers
  /// must retry once the [adInitializationProvider] reports the SDK as ready.
  BannerAd? createBannerAd(VoidCallback onLoaded, void Function(LoadAdError) onFailed) {
    if (!_isSdkInitialized || !_hasInternet()) {
      log('AdService: Banner creation skipped (Internet: ${_hasInternet()}, SDK: $_isSdkInitialized)');
      return null;
    }

    log('AdService: Banner ad request started (unit: ${AdUnits.banner})');
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
          log('AdService: Banner ad failed to load: ${error.code} ${error.message}');
          log('AdService: Banner ad object disposed due to load failure');
          ad.dispose();
          onFailed(error);
        },
      ),
    )..load();
  }
}
