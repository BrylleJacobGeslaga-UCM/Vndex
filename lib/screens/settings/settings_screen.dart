import 'package:flutter/material.dart';

import 'about_screen.dart';
import 'appearance_screen.dart';
import 'content_screen.dart';
import 'data_screen.dart';

/// Settings home: one row per category.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, String title, String subtitle, Widget screen) =>
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Icon(icon, size: 28),
          title: Text(title),
          subtitle: Text(subtitle),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => screen),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          item(Icons.palette_outlined, 'Appearance', 'Theme, date format',
              const AppearanceScreen()),
          item(Icons.eighteen_up_rating_outlined, 'Content',
              'Sensitive covers, sexual content tags', const ContentScreen()),
          item(Icons.storage_outlined, 'Data and storage',
              'Library size, clear data', const DataScreen()),
          item(Icons.info_outline, 'About', 'Version, credits, licenses',
              const AboutScreen()),
        ],
      ),
    );
  }
}
