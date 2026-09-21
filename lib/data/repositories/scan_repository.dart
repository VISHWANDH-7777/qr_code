import 'package:hive/hive.dart';
import '../../core/constants/hive_box_names.dart';
import '../../models/scan_record.dart';

class ScanRepository {
  final Box<ScanRecord> _box = Hive.box<ScanRecord>(HiveBoxNames.scanHistory);

  Future<void> addScan(ScanRecord record) async {
    await _box.put(record.id, record);
  }

  List<ScanRecord> getScans() {
    return _box.values.toList()..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
  }

  List<ScanRecord> getRecentScans({int limit = 5}) {
    final scans = getScans();
    return scans.take(limit).toList();
  }

  Future<void> updateScan(ScanRecord record) async {
    await _box.put(record.id, record);
  }

  Future<void> deleteScan(String id) async {
    await _box.delete(id);
  }

  Future<void> clearHistory() async {
    await _box.clear();
  }

  Future<void> toggleFavorite(String id) async {
    final record = _box.get(id);
    if (record != null) {
      record.isFavorite = !record.isFavorite;
      await record.save();
    }
  }

  List<ScanRecord> getFavorites() {
    return _box.values.where((r) => r.isFavorite).toList()
      ..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
  }
}
