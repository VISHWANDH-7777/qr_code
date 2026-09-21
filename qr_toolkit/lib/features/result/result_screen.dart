import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/scan_record.dart';
import '../../core/utils/result_parser.dart';
import '../../data/providers/repository_providers.dart';
import '../../data/providers/history_provider.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final ScanRecord record;

  const ResultScreen({super.key, required this.record});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  late ScanRecord _currentRecord;

  @override
  void initState() {
    super.initState();
    _currentRecord = widget.record;
  }

  Future<void> _toggleFavorite() async {
    await ref.read(scanRepositoryProvider).toggleFavorite(_currentRecord.id);
    ref.read(historyProvider.notifier).refresh();
    setState(() {
      _currentRecord.isFavorite = !_currentRecord.isFavorite;
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _currentRecord.rawContent));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  void _shareContent() {
    // ignore: deprecated_member_use
    Share.share(_currentRecord.rawContent);
  }

  Future<void> _performAction() async {
    final parsed = ResultParser.parse(_currentRecord.rawContent);
    
    switch (parsed.action) {
      case 'open_url':
        final url = Uri.parse(parsed.rawValue);
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        }
        break;
      case 'call_phone':
        final url = Uri.parse('tel:${parsed.displayTitle}');
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        }
        break;
      case 'send_email':
        final email = parsed.details?['email'];
        if (email != null) {
          final url = Uri.parse('mailto:$email');
          if (await canLaunchUrl(url)) {
            await launchUrl(url);
          }
        }
        break;
      // Implement other actions as needed (wifi, contact, sms)
      default:
        _copyToClipboard();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final parsed = ResultParser.parse(_currentRecord.rawContent);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Result'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _currentRecord.isFavorite ? Icons.star : Icons.star_border,
              color: _currentRecord.isFavorite ? Colors.yellow.shade700 : null,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(_getIconForType(parsed.type), size: 64, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      parsed.type.toUpperCase(),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      parsed.displayTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Raw Content',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(_currentRecord.rawContent),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _performAction,
                    icon: Icon(_getActionIcon(parsed.action)),
                    label: Text(_getActionLabel(parsed.action)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyToClipboard,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _shareContent,
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'website': return Icons.language;
      case 'wifi': return Icons.wifi;
      case 'email': return Icons.email;
      case 'phone': return Icons.phone;
      case 'contact': return Icons.person;
      default: return Icons.text_snippet;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'open_url': return Icons.open_in_browser;
      case 'call_phone': return Icons.phone;
      case 'send_email': return Icons.send;
      case 'add_contact': return Icons.person_add;
      case 'connect_wifi': return Icons.wifi;
      default: return Icons.copy;
    }
  }

  String _getActionLabel(String action) {
    switch (action) {
      case 'open_url': return 'Open Website';
      case 'call_phone': return 'Call Phone';
      case 'send_email': return 'Send Email';
      case 'add_contact': return 'Add Contact';
      case 'connect_wifi': return 'Connect to WiFi';
      default: return 'Copy Text';
    }
  }
}
