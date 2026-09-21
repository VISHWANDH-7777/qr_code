import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';

import '../../models/generated_qr_record.dart';
import '../../data/providers/repository_providers.dart';
import '../../data/providers/history_provider.dart';
import '../../core/services/export_service.dart';
import 'package:share_plus/share_plus.dart';

class QRPreviewScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;

  const QRPreviewScreen({super.key, required this.data});

  @override
  ConsumerState<QRPreviewScreen> createState() => _QRPreviewScreenState();
}

class _QRPreviewScreenState extends ConsumerState<QRPreviewScreen> {
  late Color _qrColor;
  final Color _backgroundColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _qrColor = widget.data['qrColor'] != null ? Color(widget.data['qrColor']) : Colors.black;
  }

  void _saveToApp() async {
    final record = GeneratedQRRecord(
      id: const Uuid().v4(),
      type: widget.data['type'],
      name: widget.data['title'],
      content: widget.data['content'],
      createdAt: DateTime.now(),
      // ignore: deprecated_member_use
      qrColor: _qrColor.value,
      // ignore: deprecated_member_use
      backgroundColor: _backgroundColor.value,
    );

    await ref.read(qrRepositoryProvider).saveGeneratedQR(record);
    ref.read(historyProvider.notifier).refresh();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR Code saved to History!')),
      );
    }
  }

  void _saveToGallery() async {
    final success = await ExportService.exportQRImage(
      data: widget.data['content'],
      foregroundColor: _qrColor,
      backgroundColor: _backgroundColor,
      fileName: widget.data['title'] ?? 'my_qr_code',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'QR exported to gallery!' : 'Failed to export QR.')),
      );
    }
  }

  void _share() {
    // ignore: deprecated_member_use
    Share.share(widget.data['content']);
  }

  @override
  Widget build(BuildContext context) {
    final String content = widget.data['content'];
    final String title = widget.data['title'];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('QR Preview'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              color: _backgroundColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: QrImageView(
                  data: content,
                  version: QrVersions.auto,
                  size: 250.0,
                  // ignore: deprecated_member_use
                  foregroundColor: _qrColor,
                  // ignore: deprecated_member_use
                  backgroundColor: _backgroundColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 32),
            // Customization tools
            Text('Customize', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildColorPicker('QR Color', _qrColor, (c) => setState(() => _qrColor = c)),
              ],
            ),
            const SizedBox(height: 32),
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () => context.go('/create'),
                  icon: const Icon(Icons.add),
                  label: const Text('Create New'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saveToApp,
                        icon: const Icon(Icons.save),
                        label: const Text('Save'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _share,
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saveToGallery,
                        icon: const Icon(Icons.download),
                        label: const Text('Export'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker(String label, Color currentColor, Function(Color) onSelect) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _colorDot(Colors.black, currentColor, onSelect),
            _colorDot(Colors.blue, currentColor, onSelect),
            _colorDot(Colors.red, currentColor, onSelect),
            _colorDot(Colors.white, currentColor, onSelect, true),
          ],
        ),
      ],
    );
  }

  Widget _colorDot(Color color, Color selectedColor, Function(Color) onSelect, [bool hasBorder = false]) {
    final isSelected = color == selectedColor;
    return GestureDetector(
      onTap: () => onSelect(color),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: hasBorder || isSelected
              ? Border.all(color: isSelected ? Colors.green : Colors.grey, width: 2)
              : null,
        ),
        child: isSelected ? Icon(Icons.check, color: color == Colors.white ? Colors.black : Colors.white, size: 16) : null,
      ),
    );
  }
}
