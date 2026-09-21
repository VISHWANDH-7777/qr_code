import 'package:hive/hive.dart';

part 'scan_record.g.dart';

@HiveType(typeId: 0)
class ScanRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String type; // e.g. website, wifi, text

  @HiveField(2)
  final String format; // e.g. QR_CODE, CODE_128

  @HiveField(3)
  final String rawContent;

  @HiveField(4)
  final String title;

  @HiveField(5)
  final String subtitle;

  @HiveField(6)
  final DateTime scannedAt;

  @HiveField(7)
  bool isFavorite;

  ScanRecord({
    required this.id,
    required this.type,
    required this.format,
    required this.rawContent,
    required this.title,
    required this.subtitle,
    required this.scannedAt,
    this.isFavorite = false,
  });
}
