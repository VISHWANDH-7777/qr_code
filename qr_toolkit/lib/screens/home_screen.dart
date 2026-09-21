import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR & Barcode Toolkit'),
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(LucideIcons.qrCode, color: Color(0xFF2563EB)),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scan, create and manage codes',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            
            // Hero Action
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(LucideIcons.scan, size: 28),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  'Scan QR or Barcode\nInstantly scan any supported code',
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.4),
                ),
              ),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Secondary Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(LucideIcons.plusSquare, size: 18),
                    label: const Text('Create QR'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(LucideIcons.image, size: 18),
                    label: const Text('From Gallery'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Quick Create Section
            const Text(
              'Quick Create',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _buildQuickToolCard(LucideIcons.globe, 'Website'),
                _buildQuickToolCard(LucideIcons.type, 'Text'),
                _buildQuickToolCard(LucideIcons.wifi, 'Wi-Fi'),
                _buildQuickToolCard(LucideIcons.user, 'Contact'),
                _buildQuickToolCard(LucideIcons.phone, 'Phone'),
                _buildQuickToolCard(LucideIcons.mail, 'Email'),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Recent Scans Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Scans',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildRecentScanItem(LucideIcons.globe, 'https://example.com', 'Today, 10:42 AM'),
            _buildRecentScanItem(LucideIcons.wifi, 'Guest Network', 'Yesterday, 4:15 PM'),
            _buildRecentScanItem(LucideIcons.scan, '812491294812', 'Aug 10, 2:30 PM'),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickToolCard(IconData icon, String label) {
    return Card(
      color: const Color(0xFFEFF6FF), // Light Blue tint
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF2563EB), size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentScanItem(IconData icon, String title, String timestamp) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(timestamp),
        trailing: IconButton(
          icon: const Icon(LucideIcons.star, size: 20, color: Color(0xFF64748B)),
          onPressed: () {},
        ),
        onTap: () {},
      ),
    );
  }
}
