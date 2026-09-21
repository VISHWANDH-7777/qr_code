import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/utils/result_parser.dart';
import '../../models/scan_record.dart';
import '../../data/providers/repository_providers.dart';
import '../../data/providers/history_provider.dart';
import '../settings/settings_screen.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final MobileScannerController controller = MobileScannerController(
    formats: const [BarcodeFormat.all],
  );

  bool _isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      final rawValue = barcode.rawValue;

      if (rawValue != null) {
        setState(() => _isProcessing = true);
        
        final parsedResult = ResultParser.parse(rawValue);
        
        final scanRecord = ScanRecord(
          id: const Uuid().v4(),
          type: parsedResult.type,
          format: barcode.format.name,
          rawContent: rawValue,
          title: parsedResult.displayTitle,
          subtitle: rawValue,
          scannedAt: DateTime.now(),
        );

        // Save to Hive
        final settings = ref.read(settingsProvider);
        if (settings.saveHistory) {
          await ref.read(scanRepositoryProvider).addScan(scanRecord);
          ref.read(historyProvider.notifier).refresh();
        }

        // Stop camera briefly before navigating
        await controller.stop();

        if (mounted) {
          context.push('/scan/result', extra: scanRecord).then((_) {
            if (mounted) {
              setState(() => _isProcessing = false);
              controller.start();
            }
          });
        }
      }
    }
  }

  void _scanFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() => _isProcessing = true);
      final BarcodeCapture? capture = await controller.analyzeImage(image.path);
      
      if (capture != null && capture.barcodes.isNotEmpty) {
        final barcode = capture.barcodes.first;
        final rawValue = barcode.rawValue;
        
        if (rawValue != null) {
          final parsedResult = ResultParser.parse(rawValue);
          final scanRecord = ScanRecord(
            id: const Uuid().v4(),
            type: parsedResult.type,
            format: barcode.format.name,
            rawContent: rawValue,
            title: parsedResult.displayTitle,
            subtitle: rawValue,
            scannedAt: DateTime.now(),
          );

          final settings = ref.read(settingsProvider);
          if (settings.saveHistory) {
            await ref.read(scanRepositoryProvider).addScan(scanRecord);
            ref.read(historyProvider.notifier).refresh();
          }
          
          if (mounted) {
            context.push('/scan/result', extra: scanRecord).then((_) {
              if (mounted) setState(() => _isProcessing = false);
            });
          }
        } else {
          setState(() => _isProcessing = false);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No QR/Barcode found in image.')));
        }
      } else {
        setState(() => _isProcessing = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No QR/Barcode found in image.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR or Barcode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: _scanFromGallery,
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.auto:
                  case TorchState.unavailable:
                    return const Icon(Icons.flash_auto, color: Colors.grey);
                }
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, state, child) {
                switch (state.cameraDirection) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                  case CameraFacing.external:
                  case CameraFacing.unknown:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 4),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
