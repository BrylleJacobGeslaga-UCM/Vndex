import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vn_status.dart';
import '../../providers/providers.dart';
import '../search/search_screen.dart';
import 'widgets/status_list_view.dart';

/// Main screen: one tab per status list, with a count on each tab.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const statuses = VnStatus.values;
    final counts = ref.watch(statusCountsProvider).maybeWhen(
          data: (c) => c,
          orElse: () => const <VnStatus, int>{},
        );

    return DefaultTabController(
      length: statuses.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Vndex'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (final s in statuses)
                Tab(
                  icon: Icon(s.icon),
                  text: counts[s] == null ? s.label : '${s.label} (${counts[s]})',
                ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final s in statuses) StatusListView(status: s),
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
