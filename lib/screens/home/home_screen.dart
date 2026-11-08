import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_settings.dart';
import '../../models/vn_status.dart';
import '../../providers/providers.dart';
import '../browse/browse_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/status_list_view.dart';

/// Main screen: one tab per status list, with a count on each tab.
/// Top bar: search your lists, sort, settings.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _searching = false;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _startSearch() => setState(() => _searching = true);

  void _stopSearch() {
    _search.clear();
    ref.read(librarySearchProvider.notifier).set('');
    setState(() => _searching = false);
  }

  @override
  Widget build(BuildContext context) {
    const statuses = VnStatus.values;
    final counts = ref.watch(statusCountsProvider).maybeWhen(
          data: (c) => c,
          orElse: () => const <VnStatus, int>{},
        );
    final sort = ref.watch(settingsProvider.select((s) => s.listSort));

    return DefaultTabController(
      length: statuses.length,
      child: PopScope(
        // Back button closes the search box first.
        canPop: !_searching,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _searching) _stopSearch();
        },
        child: Scaffold(
          appBar: AppBar(
            leading: _searching
                ? IconButton(
                    tooltip: 'Close search',
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _stopSearch,
                  )
                : null,
            title: _searching
                ? TextField(
                    controller: _search,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search your lists…',
                      border: InputBorder.none,
                    ),
                    onChanged: (q) =>
                        ref.read(librarySearchProvider.notifier).set(q),
                  )
                : const Text('Vndex'),
            actions: [
              if (!_searching)
                IconButton(
                  tooltip: 'Search your lists',
                  icon: const Icon(Icons.search),
                  onPressed: _startSearch,
                ),
              PopupMenuButton<ListSort>(
                tooltip: 'Sort',
                icon: const Icon(Icons.sort),
                initialValue: sort,
                onSelected: (s) => ref
                    .read(settingsProvider.notifier)
                    .update((c) => c.copyWith(listSort: s)),
                itemBuilder: (_) => [
                  for (final s in ListSort.values)
                    PopupMenuItem(
                      value: s,
                      child: Row(
                        children: [
                          Icon(s.icon, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text(s.label)),
                          if (s == sort) const Icon(Icons.check, size: 18),
                        ],
                      ),
                    ),
                ],
              ),
              if (!_searching)
                IconButton(
                  tooltip: 'Settings',
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
            ],
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
            icon: const Icon(Icons.explore_outlined),
            label: const Text('Browse'),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const BrowseScreen()))
                // You may have added VNs while browsing.
                .then((_) => ref.invalidate(statusListProvider)),
          ),
        ),
      ),
    );
  }
}
