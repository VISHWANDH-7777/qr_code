import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ExportService {
  static Future<bool> exportQRImage({
    required String data,
    required Color foregroundColor,
    required Color backgroundColor,
    required String fileName,
  }) async {
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final request = await Gal.requestAccess();
        if (!request) return false;
      }

      final qrValidationResult = QrValidator.validate(
        data: data,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );

      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCode = qrValidationResult.qrCode!;
        final painter = QrPainter.withQr(
          qr: qrCode,
          // ignore: deprecated_member_use
          color: foregroundColor,
          // ignore: deprecated_member_use
          emptyColor: backgroundColor,
          gapless: true,
        );

        final dir = await getTemporaryDirectory();
        // Clean filename
        final cleanName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
        final path = '${dir.path}/qr_$cleanName.png';

        final picData = await painter.toImageData(1024, format: ui.ImageByteFormat.png);
        if (picData != null) {
          final file = File(path);
          await file.writeAsBytes(picData.buffer.asUint8List());
          await Gal.putImage(path);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Export failed: $e');
      return false;
    }
  }
}
