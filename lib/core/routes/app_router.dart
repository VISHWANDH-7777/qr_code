import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';
import '../services/ad_state_provider.dart';
import '../services/rate_service.dart';
import '../../features/rating/rate_popup.dart';
import 'dart:async';

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
  Timer? _ratePromptTimer;

  @override
  void initState() {
    super.initState();
    _startRatePromptTimer();
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
    final adService = ref.read(adServiceProvider);
    _bannerAd = adService.createBannerAd(
      () {
        if (mounted) setState(() => _isAdLoaded = true);
      },
      (error) {
        if (mounted) {
          setState(() => _isAdLoaded = false);
          // Retry loading after a delay
          Future.delayed(const Duration(seconds: 30), () {
            if (mounted && !_isAdLoaded) {
              _bannerAd?.dispose();
              _loadBannerAd();
            }
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _ratePromptTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(adInitializationProvider, (previous, next) {
      if (next && !_isAdLoaded && _bannerAd == null) {
        _loadBannerAd();
      }
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
