import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/hive_box_names.dart';
import 'core/routes/app_router.dart';
import 'models/scan_record.dart';
import 'models/generated_qr_record.dart';
import 'models/settings_record.dart';
import 'features/settings/settings_screen.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/ad_service.dart';
import 'screens/no_internet_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(ScanRecordAdapter());
  Hive.registerAdapter(GeneratedQRRecordAdapter());
  Hive.registerAdapter(SettingsRecordAdapter());

  await Hive.openBox<ScanRecord>(HiveBoxNames.scanHistory);
  await Hive.openBox<GeneratedQRRecord>(HiveBoxNames.generatedQr);
  await Hive.openBox<SettingsRecord>(HiveBoxNames.settings);
  await Hive.openBox('app_state');

  runApp(const ProviderScope(child: QRToolkitApp()));
}

class QRToolkitApp extends ConsumerWidget {
  const QRToolkitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Start the Mobile Ads SDK while the app shell is being created.
    ref.watch(adServiceProvider);
    final themeMode = ref.watch(themeModeProvider);
    final internetStatus = ref.watch(internetStatusProvider);

    if (internetStatus != InternetStatus.connected) {
      return MaterialApp(
        title: 'QR & Barcode Toolkit',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        debugShowCheckedModeBanner: false,
        home: internetStatus == InternetStatus.checking
            ? const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Checking internet connection...'),
                    ],
                  ),
                ),
              )
            : const NoInternetScreen(),
      );
    }

    return MaterialApp.router(
      title: 'QR & Barcode Toolkit',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
