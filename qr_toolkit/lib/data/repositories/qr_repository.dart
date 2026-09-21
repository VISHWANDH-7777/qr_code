import 'package:hive/hive.dart';
import '../../core/constants/hive_box_names.dart';
import '../../models/generated_qr_record.dart';

class QRRepository {
  final Box<GeneratedQRRecord> _box = Hive.box<GeneratedQRRecord>(HiveBoxNames.generatedQr);

  Future<void> saveGeneratedQR(GeneratedQRRecord record) async {
    await _box.put(record.id, record);
  }

  List<GeneratedQRRecord> getGeneratedQRs() {
    return _box.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> updateGeneratedQR(GeneratedQRRecord record) async {
    await _box.put(record.id, record);
  }

  Future<void> deleteQR(String id) async {
    await _box.delete(id);
  }

  Future<void> toggleFavorite(String id) async {
    final record = _box.get(id);
    if (record != null) {
      record.isFavorite = !record.isFavorite;
      await record.save();
    }
  }

  List<GeneratedQRRecord> getFavorites() {
    return _box.values.where((r) => r.isFavorite).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
