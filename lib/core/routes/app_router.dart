import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';
import '../services/ad_state_provider.dart';
import '../services/connectivity_service.dart';
import '../services/rate_service.dart';
import '../../features/rating/rate_popup.dart';
import 'dart:async';
import 'dart:developer' show log;

import '../../features/home/home_screen.dart';
import '../../features/scanner/scanner_screen.dart';
import '../../features/result/result_screen.dart';
import '../../features/generator/generator_screen.dart';
import '../../features/generator/qr_form_screen.dart';
import '../../features/generator/qr_preview_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/favorites/favorites_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../models/scan_record.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (BuildContext context, GoRouterState state, StatefulNavigationShell navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/',
                builder: (BuildContext context, GoRouterState state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/scan',
                builder: (BuildContext context, GoRouterState state) => const ScannerScreen(),
                routes: [
                  GoRoute(
                    path: 'result',
                    builder: (BuildContext context, GoRouterState state) {
                      final record = state.extra as ScanRecord;
                      return ResultScreen(record: record);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/create',
                builder: (BuildContext context, GoRouterState state) => const GeneratorScreen(),
                routes: [
                  GoRoute(
                    path: 'form/:type',
                    builder: (BuildContext context, GoRouterState state) {
                      final type = state.pathParameters['type'] ?? 'text';
                      return QRFormScreen(type: type);
                    },
                  ),
                  GoRoute(
                    path: 'preview',
                    builder: (BuildContext context, GoRouterState state) {
                      final data = state.extra as Map<String, dynamic>;
                      return QRPreviewScreen(data: data);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/history',
                builder: (BuildContext context, GoRouterState state) => const HistoryScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}

class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isBannerLoading = false;
  int _bannerRetryCount = 0;
  static const int _maxBannerRetries = 5;
  Timer? _ratePromptTimer;

  @override
  void initState() {
    super.initState();
    _startRatePromptTimer();

    // The ads SDK is initialized while the app shell is being created, so it can
    // already be ready before this widget exists. `ref.listen` never fires for a
    // value that changed before the listener was registered, therefore the banner
    // is also requested once here.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBannerAd());
  }

  void _startRatePromptTimer() {
    _ratePromptTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!mounted) return;
      
      final rateService = ref.read(rateServiceProvider);
      if (rateService.canShowRatePrompt()) {
        // Only show if user is on Home (0) or History (3) tab, so we don't interrupt Scan or Create
        if (widget.navigationShell.currentIndex == 0 || widget.navigationShell.currentIndex == 3) {
          rateService.updateLastRatePromptTime();
          RatePopup.showRateDialog(context, ref);
        }
      }
    });
  }

  void _loadBannerAd() {
    if (!mounted || _isAdLoaded || _isBannerLoading) return;

    final adService = ref.read(adServiceProvider);
    final ad = adService.createBannerAd(
      () {
        if (!mounted) return;
        setState(() {
          _isBannerLoading = false;
          _isAdLoaded = true;
        });
      },
      (error) {
        if (!mounted) return;
        setState(() {
          _isBannerLoading = false;
          _isAdLoaded = false;
          _bannerAd = null;
        });
        _scheduleBannerRetry(error.message);
      },
    );

    if (ad == null) {
      // The SDK is not ready yet (or the device is offline). The
      // adInitializationProvider listener retries as soon as it becomes ready.
      return;
    }

    _isBannerLoading = true;
    _bannerAd = ad;
  }

  void _scheduleBannerRetry(String reason) {
    if (_bannerRetryCount >= _maxBannerRetries) {
      log('AdService: banner retries exhausted ($reason)');
      return;
    }

    _bannerRetryCount++;
    final delay = Duration(seconds: 15 * _bannerRetryCount);
    log('AdService: banner retry $_bannerRetryCount scheduled in ${delay.inSeconds}s ($reason)');

    Future.delayed(delay, () {
      if (mounted && !_isAdLoaded) _loadBannerAd();
    });
  }

  @override
  void dispose() {
    _ratePromptTimer?.cancel();
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Load the banner as soon as the SDK is ready, and retry when the device
    // comes back online. `WidgetRef.listen` has no `fireImmediately`, so the
    // case where the SDK became ready before this widget existed is handled by
    // the post frame callback in `initState`.
    ref.listen<bool>(adInitializationProvider, (previous, next) {
      if (next) _loadBannerAd();
    });

    ref.listen<InternetStatus>(internetStatusProvider, (previous, next) {
      if (next == InternetStatus.connected) _loadBannerAd();
    });

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isAdLoaded && _bannerAd != null)
            SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          NavigationBar(
            selectedIndex: widget.navigationShell.currentIndex,
            onDestinationSelected: (int index) {
              widget.navigationShell.goBranch(
                index,
                initialLocation: index == widget.navigationShell.currentIndex,
              );
            },
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.qr_code_scanner_outlined),
                selectedIcon: Icon(Icons.qr_code_scanner),
                label: 'Scan',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_box_outlined),
                selectedIcon: Icon(Icons.add_box),
                label: 'Create',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: 'History',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
