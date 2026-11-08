import 'package:flutter/material.dart';

import '../../models/vn_status.dart';
import '../search/search_screen.dart';
import 'widgets/empty_list.dart';

/// Main screen: one tab per status list.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const statuses = VnStatus.values;

    return DefaultTabController(
      length: statuses.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Vndex'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (final s in statuses) Tab(icon: Icon(s.icon), text: s.label),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Step 5 replaces these with real lists from the local database.
            for (final s in statuses) EmptyList(status: s),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.search),
          label: const Text('Find a VN'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          ),
        ),
      ),
    );
  }
}
