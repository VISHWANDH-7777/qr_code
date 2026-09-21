import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/settings_record.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  final box = Hive.box<SettingsRecord>('settings');
  final settings = box.get('app_settings') ?? SettingsRecord();
  
  switch (settings.themeMode) {
    case 'dark': return ThemeMode.dark;
    case 'light': return ThemeMode.light;
    default: return ThemeMode.light;
  }
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsRecord>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<SettingsRecord> {
  SettingsNotifier() : super(_loadSettings());

  static SettingsRecord _loadSettings() {
    final box = Hive.box<SettingsRecord>('settings');
    final settings = box.get('app_settings') ?? SettingsRecord();
    return SettingsRecord(
      themeMode: settings.themeMode,
      autoOpenLinks: settings.autoOpenLinks,
      saveHistory: settings.saveHistory,
      defaultQRStyle: settings.defaultQRStyle,
      defaultExportQuality: settings.defaultExportQuality,
    );
  }

  Future<void> setSaveHistory(bool enabled) async {
    final box = Hive.box<SettingsRecord>('settings');
    var settings = box.get('app_settings');
    if (settings == null) {
      settings = SettingsRecord()..saveHistory = enabled;
      await box.put('app_settings', settings);
    } else {
      settings.saveHistory = enabled;
      await settings.save();
    }
    state = _loadSettings();
  }
}


class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _updateThemeMode(WidgetRef ref, String modeStr, ThemeMode mode) async {
    final box = Hive.box<SettingsRecord>('settings');
    var settings = box.get('app_settings');
    if (settings == null) {
      settings = SettingsRecord()..themeMode = modeStr;
      await box.put('app_settings', settings);
    } else {
      settings.themeMode = modeStr;
      await settings.save();
    }
    ref.read(themeModeProvider.notifier).state = mode;
  }

  // _saveSetting removed in favor of settingsProvider

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final box = Hive.box<SettingsRecord>('settings');
    final rawSettings = box.get('app_settings') ?? SettingsRecord();
    ref.watch(themeModeProvider); // Watch to rebuild UI when theme changes

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Appearance'),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Theme'),
            trailing: DropdownButton<String>(
              value: rawSettings.themeMode,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  ThemeMode mode = ThemeMode.light;
                  if (newValue == 'dark') mode = ThemeMode.dark;
                  _updateThemeMode(ref, newValue, mode);
                }
              },
              items: const [
                DropdownMenuItem(value: 'light', child: Text('Light')),
                DropdownMenuItem(value: 'dark', child: Text('Dark')),
              ],
            ),
          ),
          
          _buildSectionHeader(context, 'History'),
          SwitchListTile(
            title: const Text('Save Scan History'),
            subtitle: const Text('Automatically save scanned QR codes and barcodes'),
            secondary: const Icon(Icons.history),
            value: settings.saveHistory,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).setSaveHistory(val);
            },
          ),
          
          _buildSectionHeader(context, 'About'),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('Version 1.0.0'),
            subtitle: Text('QR & Barcode Toolkit'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
