import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/rate_service.dart';

class RatePopup {
  static void showRateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.star, color: Colors.amber),
              SizedBox(width: 8),
              Text('Enjoying the app?'),
            ],
          ),
          content: const Text('Help us improve QR & Barcode Toolkit.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(rateServiceProvider).updateLastRatePromptTime();
              },
              child: const Text('Maybe Later'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                final InAppReview inAppReview = InAppReview.instance;
                
                try {
                  if (await inAppReview.isAvailable()) {
                    await inAppReview.requestReview();
                    await ref.read(rateServiceProvider).setHasRatedApp();
                  } else {
                    // Fallback to open store listing if API is unavailable
                    await inAppReview.openStoreListing(appStoreId: '...', microsoftStoreId: '...');
                    await ref.read(rateServiceProvider).setHasRatedApp();
                  }
                } catch (e) {
                  // Ignore errors, don't crash
                  debugPrint('InAppReview error: $e');
                }
              },
              child: const Text('Rate Us'),
            ),
          ],
        );
      },
    );
  }
}
