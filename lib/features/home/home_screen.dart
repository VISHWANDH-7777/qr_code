import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/history_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyItems = ref.watch(historyProvider);

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
            ElevatedButton.icon(
              onPressed: () => context.go('/scan'),
              icon: const Icon(Icons.qr_code_scanner, size: 32),
              label: const Text('Scan QR or Barcode', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
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
