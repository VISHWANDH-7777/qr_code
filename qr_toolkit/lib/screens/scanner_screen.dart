import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Camera preview background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Scan Code',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.zap),
            onPressed: () {},
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Placeholder for Camera Preview
          Container(
            color: Colors.black,
            child: const Center(
              child: Text(
                'Camera Preview Active',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ),
          
          // Scanning Frame Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF2563EB), width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  // Animated scan line placeholder
                  Positioned(
                    top: 125,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 2,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF2563EB),
                            blurRadius: 8,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          
          // Instruction Text
          const Positioned(
            bottom: 200,
            left: 0,
            right: 0,
            child: Text(
              'Align the code inside the frame',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          // Bottom Controls
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBottomControl(LucideIcons.image, 'Gallery'),
                _buildBottomControl(LucideIcons.keyboard, 'Manual Entry'),
              ],
            ),
          ),
          
          // Support indicators
          const Positioned(
            bottom: 110,
            left: 0,
            right: 0,
            child: Text(
              'QR • Barcode • Data Matrix',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControl(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(38),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
