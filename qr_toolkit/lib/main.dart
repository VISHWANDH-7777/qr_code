import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/hive_box_names.dart';
import 'core/routes/app_router.dart';
import 'models/scan_record.dart';
import 'models/generated_qr_record.dart';
import 'models/settings_record.dart';
import 'features/settings/settings_screen.dart';

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

  // Initialize AdMob
  await MobileAds.instance.initialize();

  runApp(
    const ProviderScope(
      child: QRToolkitApp(),
    ),
  );
}

class QRToolkitApp extends ConsumerWidget {
  const QRToolkitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
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
