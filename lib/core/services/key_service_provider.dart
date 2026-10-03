import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const String _boxName = 'app_state';
const String _scanKeysKey = 'scanKeys';
const String _createKeysKey = 'createKeys';

class KeyNotifier extends StateNotifier<int> {
  final String keyName;

  KeyNotifier(this.keyName) : super(0) {
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    final box = Hive.box(_boxName);
    state = box.get(keyName, defaultValue: 0) as int;
  }

  Future<void> addKeys(int amount) async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    final box = Hive.box(_boxName);
    final newAmount = state + amount;
    await box.put(keyName, newAmount);
    state = newAmount;
  }

  Future<bool> consumeKey() async {
    if (state <= 0) return false;
    
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    final box = Hive.box(_boxName);
    final newAmount = state - 1;
    await box.put(keyName, newAmount);
    state = newAmount;
    return true;
  }
}

final scanKeysProvider = StateNotifierProvider<KeyNotifier, int>((ref) {
  return KeyNotifier(_scanKeysKey);
});

final createKeysProvider = StateNotifierProvider<KeyNotifier, int>((ref) {
  return KeyNotifier(_createKeysKey);
});
