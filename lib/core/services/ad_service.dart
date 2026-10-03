import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/ad_units.dart';
import 'connectivity_service.dart';
import 'ad_state_provider.dart';
import 'key_service_provider.dart';

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
      _markSdkInitialized();
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

  static Future<void> initializeAds() async {
    if (_isSdkInitialized) return;
    
    log('AdService: SDK initialization started');

    if (kDebugMode && debugTestDeviceIds.isNotEmpty) {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: debugTestDeviceIds),
      );
      log('AdService: test devices configured: ${debugTestDeviceIds.join(', ')}');
    }

    try {
      final ConsentRequestParameters params = ConsentRequestParameters(
        consentDebugSettings: (kDebugMode && debugTestDeviceIds.isNotEmpty)
            ? ConsentDebugSettings(
                debugGeography: DebugGeography.debugGeographyEea,
                testIdentifiers: debugTestDeviceIds,
              )
            : null,
      );

      // Completer to wait for consent flow before initializing SDK
      final completer = Completer<void>();

      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          log('AdService: Consent info update succeeded');
          if (await ConsentInformation.instance.isConsentFormAvailable()) {
            ConsentForm.loadConsentForm(
              (ConsentForm consentForm) async {
                final status = await ConsentInformation.instance.getConsentStatus();
                if (status == ConsentStatus.required) {
                  consentForm.show((FormError? formError) {
                    if (formError != null) {
                      log('AdService: Consent form show error: ${formError.message}');
                    }
                    if (!completer.isCompleted) completer.complete();
                  });
                } else {
                  if (!completer.isCompleted) completer.complete();
                }
              },
              (FormError formError) {
                log('AdService: Consent form load error: ${formError.message}');
                if (!completer.isCompleted) completer.complete();
              },
            );
          } else {
            if (!completer.isCompleted) completer.complete();
          }
        },
        (FormError error) {
          log('AdService: Consent info update failed: ${error.message}');
          if (!completer.isCompleted) completer.complete();
        },
      );
      
      await completer.future;
    } catch (e) {
      log('AdService: Error during consent request: $e');
    }

    try {
      final InitializationStatus status = await MobileAds.instance.initialize();
      _isSdkInitialized = true;
      log('AdService: SDK initialization completed successfully.');
      
      status.adapterStatuses.forEach((key, value) {
        log('AdService: Adapter $key status: ${value.state}, description: ${value.description}');
      });
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
          // Automatically reload on failure
          Future.delayed(const Duration(seconds: 10), () {
            _preloadQrCreateInterstitial();
          });
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
          // Automatically reload on failure
          Future.delayed(const Duration(seconds: 10), () {
            _preloadScanInterstitial();
          });
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
          // Automatically reload on failure
          Future.delayed(const Duration(seconds: 10), () {
            _preloadRewarded();
          });
        },
      ),
    );
  }

  void _showQrCreateInterstitialIfAvailable(VoidCallback onContinue) {
    if (_isAdShowing || !_hasInternet() || !_isSdkInitialized) {
      log('AdService: QR Create Interstitial unavailable or cannot show (Showing: $_isAdShowing, Internet: ${_hasInternet()}, SDK: $_isSdkInitialized), proceeding.');
      onContinue();
      return;
    }

    if (_qrCreateInterstitialAd != null) {
      _showReadyQrCreateInterstitial(onContinue);
    } else {
      log('AdService: QR Create Interstitial ad not ready, loading on demand...');
      _isQrCreateInterstitialLoading = true;
      InterstitialAd.load(
        adUnitId: AdUnits.qrCreateInterstitial,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            log('AdService: QR Create Interstitial ad loaded on demand');
            _qrCreateInterstitialAd = ad;
            _isQrCreateInterstitialLoading = false;
            _showReadyQrCreateInterstitial(onContinue);
          },
          onAdFailedToLoad: (LoadAdError error) {
            log('AdService: QR Create Interstitial ad failed to load on demand: $error');
            _qrCreateInterstitialAd = null;
            _isQrCreateInterstitialLoading = false;
            onContinue();
          },
        ),
      );
    }
  }

  void _showReadyQrCreateInterstitial(VoidCallback onContinue) {
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
    if (_isAdShowing || !_hasInternet() || !_isSdkInitialized) {
      log('AdService: Scan Interstitial unavailable or cannot show, proceeding.');
      onContinue();
      return;
    }

    if (_scanInterstitialAd != null) {
      _showReadyScanInterstitial(onContinue);
    } else {
      log('AdService: Scan Interstitial ad not ready, loading on demand...');
      _isScanInterstitialLoading = true;
      InterstitialAd.load(
        adUnitId: AdUnits.scanInterstitial,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            log('AdService: Scan Interstitial ad loaded on demand');
            _scanInterstitialAd = ad;
            _isScanInterstitialLoading = false;
            _showReadyScanInterstitial(onContinue);
          },
          onAdFailedToLoad: (LoadAdError error) {
            log('AdService: Scan Interstitial ad failed to load on demand: $error');
            _scanInterstitialAd = null;
            _isScanInterstitialLoading = false;
            onContinue();
          },
        ),
      );
    }
  }

  void _showReadyScanInterstitial(VoidCallback onContinue) {
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

  void showRewardedAd(VoidCallback onContinue, {void Function(RewardItem)? onUserEarnedReward, VoidCallback? onFail}) {
    if (_isAdShowing || !_hasInternet() || !_isSdkInitialized) {
      log('AdService: Rewarded unavailable or cannot show (showing: $_isAdShowing, internet: ${_hasInternet()}, sdk: $_isSdkInitialized).');
      if (onFail != null) {
        onFail();
      } else {
        onContinue();
      }
      return;
    }

    if (_rewardedAd != null) {
      _showReadyRewardedAd(onContinue, onUserEarnedReward, onFail);
    } else {
      log('AdService: Rewarded ad not ready, loading on demand...');
      _isRewardedLoading = true;
      RewardedAd.load(
        adUnitId: AdUnits.rewarded,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            log('AdService: Rewarded ad loaded on demand');
            _rewardedAd = ad;
            _isRewardedLoading = false;
            _showReadyRewardedAd(onContinue, onUserEarnedReward, onFail);
          },
          onAdFailedToLoad: (LoadAdError error) {
            log('AdService: Rewarded ad failed to load on demand: $error');
            _rewardedAd = null;
            _isRewardedLoading = false;
            if (onFail != null) {
              onFail();
            } else {
              onContinue();
            }
          },
        ),
      );
    }
  }

  void _showReadyRewardedAd(VoidCallback onContinue, void Function(RewardItem)? onUserEarnedReward, VoidCallback? onFail) {
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
        if (onFail != null) {
          onFail();
        } else {
          onContinue();
        }
        log('AdService: Next Rewarded ad preload started');
        _preloadRewarded();
      },
    );

    _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      log('AdService: User earned reward: ${reward.amount} ${reward.type}');
      onUserEarnedReward?.call(reward);
    });
  }
  
  void showRewardedForScanKeys(VoidCallback onContinue, VoidCallback onFail) {
    bool rewardProcessed = false;
    showRewardedAd(
      onContinue, 
      onFail: onFail,
      onUserEarnedReward: (reward) {
        if (!rewardProcessed) {
          rewardProcessed = true;
          _ref.read(scanKeysProvider.notifier).addKeys(5);
        }
      }
    );
  }

  void showRewardedForCreateKeys(VoidCallback onContinue, VoidCallback onFail) {
    bool rewardProcessed = false;
    showRewardedAd(
      onContinue, 
      onFail: onFail,
      onUserEarnedReward: (reward) {
        if (!rewardProcessed) {
          rewardProcessed = true;
          _ref.read(createKeysProvider.notifier).addKeys(2);
        }
      }
    );
  }
  /// Called after a QR code was created. Shows the QR creation interstitial on
  /// every generation, then runs [onContinue] (navigation to the preview).
  ///
  /// Note: [onContinue] always runs, even when no ad is loaded, so the user is
  /// never blocked.
  Future<void> onSuccessfulCreate(VoidCallback onContinue) async {
    final bool usedKey = await _ref.read(createKeysProvider.notifier).consumeKey();
    if (usedKey) {
      log('AdService: Used Create Key, bypassing ad pattern');
      onContinue();
      return;
    }

    final int count = await _getCounter(_qrCreationCountKey) + 1;
    await _incrementCounter(_qrCreationCountKey, count);

    log('AdService: QR Create count: $count');

    if (count % 2 == 0) {
      showRewardedAd(onContinue);
    } else {
      _showQrCreateInterstitialIfAvailable(onContinue);
    }
  }

  /// Called after a successful scan. Shows the scan interstitial ad on every
  /// second scan to stay within AdMob's interstitial frequency rules.
  Future<void> onSuccessfulScan(VoidCallback onContinue) async {
    final bool usedKey = await _ref.read(scanKeysProvider.notifier).consumeKey();
    if (usedKey) {
      log('AdService: Used Scan Key, bypassing ad pattern');
      onContinue();
      return;
    }

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
