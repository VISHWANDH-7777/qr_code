import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/history_provider.dart';
import '../../core/services/key_service_provider.dart';
import '../../core/services/ad_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isAdLoading = false;

  @override
  Widget build(BuildContext context) {
    final historyItems = ref.watch(historyProvider);
    final scanKeys = ref.watch(scanKeysProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('QR & Barcode Toolkit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Scan, create and manage codes', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Chip(
                label: Text('$scanKeys Keys'),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Primary Action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/scan'),
                    icon: const Icon(Icons.qr_code_scanner, size: 24),
                    label: const Text('Scan QR or\nBarcode', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isAdLoading ? null : () {
                      setState(() => _isAdLoading = true);
                      ref.read(adServiceProvider).showRewardedForScanKeys(
                        () {
                          if (mounted) setState(() => _isAdLoading = false);
                        },
                        () {
                          if (mounted) {
                            setState(() => _isAdLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ad is currently unavailable. Please try again later.')));
                          }
                        }
                      );
                    },
                    icon: _isAdLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.play_circle_outline, size: 24),
                    label: const Text('View Ad for\n5 Keys', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Secondary Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/create'),
                    icon: const Icon(Icons.add_box),
                    label: const Text('Create QR'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/favorites'),
                    icon: const Icon(Icons.star),
                    label: const Text('Favorites'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent History', style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () => context.go('/history'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Builder(
              builder: (context) {
                final recent = historyItems.take(3).toList();
                
                if (recent.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Icon(Icons.history, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text('No recent history'),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: recent.map((record) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(record.isGenerated ? Icons.qr_code_2 : Icons.qr_code_scanner),
                      title: Text(record.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(record.type.toUpperCase()),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        if (record.isGenerated) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generated QR item.')));
                        } else {
                          context.push('/scan/result', extra: record.originalRecord);
                        }
                      },
                    ),
                  )).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
