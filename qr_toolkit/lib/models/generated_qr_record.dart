import 'package:hive/hive.dart';

part 'generated_qr_record.g.dart';

@HiveType(typeId: 1)
class GeneratedQRRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String type; // e.g. website, wifi, text

  @HiveField(2)
  final String name; // User-provided name

  @HiveField(3)
  final String content; // The encoded data

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final String? qrStyle;

  @HiveField(6)
  final int? qrColor; // Stored as integer representation of color

  @HiveField(7)
  final int? backgroundColor;

  @HiveField(8)
  final String? logoPath;

  @HiveField(9)
  final String? caption;

  @HiveField(10)
  bool isFavorite;

  @HiveField(11)
  final String? imagePath;

  GeneratedQRRecord({
    required this.id,
    required this.type,
    required this.name,
    required this.content,
    required this.createdAt,
    this.qrStyle,
    this.qrColor,
    this.backgroundColor,
    this.logoPath,
    this.caption,
    this.isFavorite = false,
    this.imagePath,
  });
}
