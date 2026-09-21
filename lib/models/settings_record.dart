import 'package:hive/hive.dart';

part 'settings_record.g.dart';

@HiveType(typeId: 2)
class SettingsRecord extends HiveObject {
  @HiveField(0)
  String themeMode; // system, light, dark

  // @HiveField(1) vibrationEnabled removed
  // @HiveField(2) soundEnabled removed

  @HiveField(3)
  bool autoOpenLinks;

  @HiveField(4)
  bool saveHistory;

  @HiveField(5)
  String defaultQRStyle;

  @HiveField(6)
  String defaultExportQuality;

  SettingsRecord({
    this.themeMode = 'light',
    this.autoOpenLinks = false,
    this.saveHistory = true,
    this.defaultQRStyle = 'default',
    this.defaultExportQuality = 'high',
  });
}
