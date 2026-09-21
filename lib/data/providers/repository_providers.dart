import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/scan_repository.dart';
import '../repositories/qr_repository.dart';

final scanRepositoryProvider = Provider<ScanRepository>((ref) {
  return ScanRepository();
});

final qrRepositoryProvider = Provider<QRRepository>((ref) {
  return QRRepository();
});
