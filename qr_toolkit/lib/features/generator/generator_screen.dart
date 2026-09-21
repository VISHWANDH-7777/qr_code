import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GeneratorScreen extends StatelessWidget {
  const GeneratorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final types = [
      {'title': 'Website', 'icon': Icons.language, 'type': 'website'},
      {'title': 'Text', 'icon': Icons.text_snippet, 'type': 'text'},
      {'title': 'Wi-Fi', 'icon': Icons.wifi, 'type': 'wifi'},
      {'title': 'Contact', 'icon': Icons.person, 'type': 'contact'},
      {'title': 'Phone', 'icon': Icons.phone, 'type': 'phone'},
      {'title': 'Email', 'icon': Icons.email, 'type': 'email'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Create QR Code')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: types.length,
        itemBuilder: (context, index) {
          final item = types[index];
          return Card(
            elevation: 2,
            child: InkWell(
              onTap: () {
                context.push('/create/form/${item['type']}');
              },
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item['title'] as String,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
