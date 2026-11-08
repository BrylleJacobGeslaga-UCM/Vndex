import 'package:flutter/material.dart';

import '../../core/constants.dart';

/// App name, version, credits and open source licenses.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Icon(Icons.auto_stories, size: 72, color: scheme.primary),
                const SizedBox(height: 12),
                Text('Vndex', style: text.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  'Visual novel tracker',
                  style: TextStyle(color: scheme.outline),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const ListTile(
            title: Text('Version'),
            subtitle: Text(AppConstants.appVersion),
          ),
          const ListTile(
            title: Text('Data source'),
            subtitle: Text(
              'VN information and covers come from VNDB.org, '
              'the community visual novel database.',
            ),
          ),
          ListTile(
            title: const Text('Open source licenses'),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Vndex',
              applicationVersion: AppConstants.appVersion,
            ),
          ),
        ],
      ),
    );
  }
}
