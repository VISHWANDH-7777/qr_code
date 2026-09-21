import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repository_providers.dart';

class HistoryItem {
  final String id;
  final String title;
  final String type;
  final DateTime date;
  final bool isFavorite;
  final bool isGenerated;
  final dynamic originalRecord;

  HistoryItem({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    required this.isFavorite,
    required this.isGenerated,
    required this.originalRecord,
  });
}

class HistoryNotifier extends Notifier<List<HistoryItem>> {
  @override
  List<HistoryItem> build() {
    return _loadHistory();
  }

  List<HistoryItem> _loadHistory() {
    final scanRepo = ref.read(scanRepositoryProvider);
    final qrRepo = ref.read(qrRepositoryProvider);

    final scans = scanRepo.getScans();
    final qrs = qrRepo.getGeneratedQRs();

    final List<HistoryItem> items = [];

    for (var scan in scans) {
      items.add(HistoryItem(
        id: scan.id,
        title: scan.title,
        type: scan.type,
        date: scan.scannedAt,
        isFavorite: scan.isFavorite,
        isGenerated: false,
        originalRecord: scan,
      ));
    }

    for (var qr in qrs) {
      items.add(HistoryItem(
        id: qr.id,
        title: qr.name,
        type: qr.type,
        date: qr.createdAt,
        isFavorite: qr.isFavorite,
        isGenerated: true,
        originalRecord: qr,
      ));
    }

    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  void refresh() {
    state = _loadHistory();
  }
}

final historyProvider = NotifierProvider<HistoryNotifier, List<HistoryItem>>(() {
  return HistoryNotifier();
});
