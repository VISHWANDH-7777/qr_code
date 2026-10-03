import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/key_service_provider.dart';

class QRFormScreen extends ConsumerStatefulWidget {
  final String type;

  const QRFormScreen({super.key, required this.type});

  @override
  ConsumerState<QRFormScreen> createState() => _QRFormScreenState();
}

class _QRFormScreenState extends ConsumerState<QRFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isAdLoading = false;
  
  // Basic controllers
  final _urlController = TextEditingController();
  final _textController = TextEditingController();
  final _nameController = TextEditingController(); // Common name for QR

  // WiFi controllers
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  String _security = 'WPA';

  // Contact controllers
  final _contactNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Warm up the interstitial so it is ready when the user taps
    // "Generate QR Code" (every generation shows an interstitial).
    ref.read(adServiceProvider).preloadQrCreateInterstitialAd();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _textController.dispose();
    _nameController.dispose();
    _ssidController.dispose();
    _passwordController.dispose();
    _contactNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _generateQR() {
    if (_formKey.currentState!.validate()) {
      String rawContent = '';
      String displayTitle = _nameController.text.trim();

      switch (widget.type) {
        case 'website':
          rawContent = _urlController.text.trim();
          if (displayTitle.isEmpty) displayTitle = 'Website';
          break;
        case 'text':
          rawContent = _textController.text.trim();
          if (displayTitle.isEmpty) displayTitle = 'Text';
          break;
        case 'wifi':
          rawContent = 'WIFI:S:${_ssidController.text};T:$_security;P:${_passwordController.text};;';
          if (displayTitle.isEmpty) displayTitle = _ssidController.text;
          break;
        case 'contact':
          rawContent = 'BEGIN:VCARD\nVERSION:3.0\nFN:${_contactNameController.text}\nTEL:${_phoneController.text}\nEMAIL:${_emailController.text}\nEND:VCARD';
          if (displayTitle.isEmpty) displayTitle = _contactNameController.text;
          break;
        case 'phone':
          rawContent = 'tel:${_phoneController.text}';
          if (displayTitle.isEmpty) displayTitle = _phoneController.text;
          break;
        case 'email':
          rawContent = 'mailto:${_emailController.text}';
          if (displayTitle.isEmpty) displayTitle = _emailController.text;
          break;
        default:
          rawContent = 'Unknown';
      }

      ref.read(adServiceProvider).onSuccessfulCreate(() {
        if (mounted) {
          context.push('/create/preview', extra: {
            'type': widget.type,
            'title': displayTitle,
            'content': rawContent,
          });
        }
      });
    }
  }

  Widget _buildFormFields() {
    switch (widget.type) {
      case 'website':
        return TextFormField(
          controller: _urlController,
          decoration: const InputDecoration(labelText: 'URL (e.g. https://example.com)'),
          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
          keyboardType: TextInputType.url,
        );
      case 'text':
        return TextFormField(
          controller: _textController,
          decoration: const InputDecoration(labelText: 'Text Content'),
          maxLines: 5,
          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
        );
      case 'wifi':
        return Column(
          children: [
            TextFormField(
              controller: _ssidController,
              decoration: const InputDecoration(labelText: 'Network Name (SSID)'),
              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _security,
              decoration: const InputDecoration(labelText: 'Security'),
              items: const [
                DropdownMenuItem(value: 'WPA', child: Text('WPA/WPA2')),
                DropdownMenuItem(value: 'WEP', child: Text('WEP')),
                DropdownMenuItem(value: 'nopass', child: Text('None')),
              ],
              onChanged: (val) => setState(() => _security = val!),
            ),
          ],
        );
      case 'contact':
        return Column(
          children: [
            TextFormField(
              controller: _contactNameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email Address'),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        );
      case 'phone':
        return TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(labelText: 'Phone Number'),
          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
          keyboardType: TextInputType.phone,
        );
      case 'email':
        return TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email Address'),
          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
          keyboardType: TextInputType.emailAddress,
        );
      default:
        return const Text('Form not implemented yet.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final createKeys = ref.watch(createKeysProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Create ${widget.type.toUpperCase()} QR'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Chip(
                label: Text('$createKeys Keys'),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'QR Code Name (Optional)',
                  helperText: 'For your own reference',
                ),
              ),
              const SizedBox(height: 24),
              _buildFormFields(),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _generateQR,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Create QR', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isAdLoading ? null : () {
                        setState(() => _isAdLoading = true);
                        ref.read(adServiceProvider).showRewardedForCreateKeys(
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
                      icon: _isAdLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.play_circle_outline, size: 20),
                      label: const Text('View Ad for\n2 Keys', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
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
            ],
          ),
        ),
      ),
    );
  }
}
