import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/generated_qr_record.dart';
import '../../data/providers/repository_providers.dart';
import '../../data/providers/history_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeFilter = 'All'; // All, Scanned, Generated, Favorites
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historyProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to delete all scan history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(scanRepositoryProvider).clearHistory();
      // Also clear generated qr history if desired? The user only says clear scan history in the dialog.
      // We'll leave it as clear scans, but we must refresh the provider.
      ref.read(historyProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyItems = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search history...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Scanned'),
                const SizedBox(width: 8),
                _buildFilterChip('Generated'),
                const SizedBox(width: 8),
                _buildFilterChip('Favorites'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Builder(
              builder: (context) {
                var filteredRecords = historyItems.where((record) {
                  final matchesSearch = record.title.toLowerCase().contains(_searchQuery) ||
                                        record.type.toLowerCase().contains(_searchQuery);
                  if (!matchesSearch) return false;

                  if (_activeFilter == 'Scanned' && record.isGenerated) return false;
                  if (_activeFilter == 'Generated' && !record.isGenerated) return false;
                  if (_activeFilter == 'Favorites' && !record.isFavorite) return false;

                  return true;
                }).toList();

                if (filteredRecords.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No history yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Scan a QR/barcode or create a QR code\nand it will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.go('/scan'),
                          child: const Text('Start Scanning'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredRecords.length,
                  itemBuilder: (context, index) {
                    final record = filteredRecords[index];
                    final DateFormat formatter = DateFormat('MMM dd, yyyy - hh:mm a');
                    
                    return Dismissible(
                      key: Key(record.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) async {
                        if (record.isGenerated) {
                          await ref.read(qrRepositoryProvider).deleteQR(record.id);
                        } else {
                          await ref.read(scanRepositoryProvider).deleteScan(record.id);
                        }
                        ref.read(historyProvider.notifier).refresh();
                      },
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                          child: Icon(_getIconForType(record.type)),
                        ),
                        title: Text(
                          record.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${record.isGenerated ? "Generated" : "Scanned"} • ${formatter.format(record.date)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'open') {
                              if (record.isGenerated) {
                                final genRecord = record.originalRecord as GeneratedQRRecord;
                                context.push('/create/preview', extra: {
                                  'type': genRecord.type,
                                  'title': genRecord.name,
                                  'content': genRecord.content,
                                  'qrColor': genRecord.qrColor,
                                });
                              } else {
                                context.push('/scan/result', extra: record.originalRecord);
                              }
                            } else if (value == 'favorite') {
                              if (record.isGenerated) {
                                await ref.read(qrRepositoryProvider).toggleFavorite(record.id);
                              } else {
                                await ref.read(scanRepositoryProvider).toggleFavorite(record.id);
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
                                if (record.isGenerated) {
                                  await ref.read(qrRepositoryProvider).deleteQR(record.id);
                                } else {
                                  await ref.read(scanRepositoryProvider).deleteScan(record.id);
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
                              child: Text(record.isFavorite ? 'Unfavorite' : 'Favorite'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                        onTap: () {
                          if (record.isGenerated) {
                            final genRecord = record.originalRecord as GeneratedQRRecord;
                            context.push('/create/preview', extra: {
                              'type': genRecord.type,
                              'title': genRecord.name,
                              'content': genRecord.content,
                              'qrColor': genRecord.qrColor,
                            });
                          } else {
                            context.push('/scan/result', extra: record.originalRecord);
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _activeFilter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _activeFilter = label);
      },
    );
  }
}
