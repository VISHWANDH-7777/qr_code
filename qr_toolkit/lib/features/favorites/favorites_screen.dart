import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/providers/repository_providers.dart';
import '../../data/providers/history_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  Widget _buildTrailingMenu(BuildContext context, WidgetRef ref, dynamic item) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'open') {
          if (item.isGenerated) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generated QR item.')));
          } else {
            context.push('/scan/result', extra: item.originalRecord);
          }
        } else if (value == 'favorite') {
          if (item.isGenerated) {
            await ref.read(qrRepositoryProvider).toggleFavorite(item.id);
          } else {
            await ref.read(scanRepositoryProvider).toggleFavorite(item.id);
          }
          ref.read(historyProvider.notifier).refresh();
        } else if (value == 'delete') {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete QR Code?'),
              content: const Text('This saved QR code will be permanently removed from your history.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );

          if (confirm == true) {
            if (item.isGenerated) {
              await ref.read(qrRepositoryProvider).deleteQR(item.id);
            } else {
              await ref.read(scanRepositoryProvider).deleteScan(item.id);
            }
            ref.read(historyProvider.notifier).refresh();
          }
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'open',
          child: Text('Open'),
        ),
        PopupMenuItem(
          value: 'favorite',
          child: Text(item.isFavorite ? 'Unfavorite' : 'Favorite'),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyItems = ref.watch(historyProvider);
    final favoriteScans = historyItems.where((i) => i.isFavorite && !i.isGenerated).toList();
    final favoriteQRs = historyItems.where((i) => i.isFavorite && i.isGenerated).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Favorites'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Scans'),
              Tab(text: 'Generated'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Scans Tab
            Builder(
              builder: (context) {
                if (favoriteScans.isEmpty) {
                  return const Center(child: Text('No favorite scans.'));
                }
                return ListView.builder(
                  itemCount: favoriteScans.length,
                  itemBuilder: (context, index) {
                    final item = favoriteScans[index];
                    return ListTile(
                      leading: const Icon(Icons.qr_code, color: Colors.blue),
                      title: Text(item.title),
                      subtitle: Text(DateFormat('MMM dd, yyyy').format(item.date)),
                      trailing: _buildTrailingMenu(context, ref, item),
                      onTap: () => context.push('/scan/result', extra: item.originalRecord),
                    );
                  },
                );
              },
            ),
            // Generated QR Tab
            Builder(
              builder: (context) {
                if (favoriteQRs.isEmpty) {
                  return const Center(child: Text('No favorite created QRs.'));
                }
                return ListView.builder(
                  itemCount: favoriteQRs.length,
                  itemBuilder: (context, index) {
                    final item = favoriteQRs[index];
                    return ListTile(
                      leading: const Icon(Icons.qr_code_2, color: Colors.green),
                      title: Text(item.title),
                      subtitle: Text(DateFormat('MMM dd, yyyy').format(item.date)),
                      trailing: _buildTrailingMenu(context, ref, item),
                      onTap: () {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generated QR item.')));
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
