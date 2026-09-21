import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final rateServiceProvider = Provider<RateService>((ref) {
  return RateService();
});

class RateService {
  // We can use a raw box or the same box since it's just key value.
  // The app opens HiveBoxNames.settings as a Box<SettingsRecord>. 
  // Wait, we need a separate box for untyped key/value, or we can use the same box if it's dynamic.
  // Let's create a specific box for this.
  
  static const String boxName = 'app_state';
  static const String _hasRatedKey = 'hasRatedApp';
  static const String _lastRatePromptTimeKey = 'lastRatePromptTime';

  bool get hasRatedApp {
    if (!Hive.isBoxOpen(boxName)) return false;
    final box = Hive.box(boxName);
    return box.get(_hasRatedKey, defaultValue: false) as bool;
  }

  Future<void> setHasRatedApp() async {
    if (!Hive.isBoxOpen(boxName)) await Hive.openBox(boxName);
    final box = Hive.box(boxName);
    await box.put(_hasRatedKey, true);
  }

  DateTime? get lastRatePromptTime {
    if (!Hive.isBoxOpen(boxName)) return null;
    final box = Hive.box(boxName);
    final ms = box.get(_lastRatePromptTimeKey) as int?;
    if (ms != null) {
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    return null;
  }

  Future<void> updateLastRatePromptTime() async {
    if (!Hive.isBoxOpen(boxName)) await Hive.openBox(boxName);
    final box = Hive.box(boxName);
    await box.put(_lastRatePromptTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  bool canShowRatePrompt() {
    if (!Hive.isBoxOpen(boxName)) return false; // Safety check
    if (hasRatedApp) return false;

    final lastPrompt = lastRatePromptTime;
    if (lastPrompt == null) return true; // First time

    final now = DateTime.now();
    final difference = now.difference(lastPrompt);
    
    // 10 minutes cooldown
    return difference.inMinutes >= 10;
  }
}
