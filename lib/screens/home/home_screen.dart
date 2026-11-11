import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vn_status.dart';
import '../../providers/providers.dart';
import '../../models/vn_collection.dart';
import '../browse/browse_screen.dart';
import '../roulette/roulette_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/library_sheet.dart';
import 'widgets/status_list_view.dart';

/// Main screen: All + one tab per list + one per collection.
/// Top bar: search your lists, roulette, Filter · Sort · Display, settings.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _searching = false;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Bring the home screen widget up to date each time the app opens.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(homeWidgetSyncProvider).sync(),
    );
  }

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
    final scheme = Theme.of(context).colorScheme;
    final counts = ref.watch(statusCountsProvider).maybeWhen(
          data: (c) => c,
          orElse: () => const <VnStatus, int>{},
        );
    final prefs = ref.watch(settingsProvider.select((s) => s.library));
    final total = counts.values.fold<int>(0, (a, b) => a + b);

    // First tab is "All" (null), then the four lists.
    // With tabs turned off, only "All" is shown.
    final tabs = prefs.showTabs ? <VnStatus?>[null, ...VnStatus.values] : <VnStatus?>[null];

    // Your collections come after the four lists.
    final collections = prefs.showTabs
        ? ref.watch(collectionsProvider).maybeWhen(
              data: (c) => c,
              orElse: () => const <VnCollection>[],
            )
        : const <VnCollection>[];
    final tabCount = tabs.length + collections.length;

    String tabLabel(String label, int? count) =>
        prefs.showTabCounts && count != null ? '$label ($count)' : label;

    return DefaultTabController(
      // Key forces a fresh controller when the number of tabs changes.
      key: ValueKey(tabCount),
      length: tabCount,
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
                : Row(
                    children: [
                      const Text('Vndex'),
                      // With no tabs, the total goes next to the title instead.
                      if (!prefs.showTabs && prefs.showTabCounts && counts.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text('$total', style: Theme.of(context).textTheme.titleMedium),
                        ),
                      ],
                    ],
                  ),
            actions: [
              if (!_searching)
                IconButton(
                  tooltip: 'Search your lists',
                  icon: const Icon(Icons.search),
                  onPressed: _startSearch,
                ),
              if (!_searching)
                IconButton(
                  tooltip: 'What should I play next?',
                  icon: const Icon(Icons.casino_outlined),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RouletteScreen()),
                  ),
                ),
              IconButton(
                tooltip: 'Filter, sort and display',
                // Accent color when a filter is on, like Mihon.
                icon: Icon(
                  Icons.filter_list,
                  color: prefs.hasActiveFilter ? scheme.primary : null,
                ),
                onPressed: () => showLibrarySheet(context),
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
            bottom: prefs.showTabs
                ? TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: [
                      for (final s in tabs)
                        s == null
                            ? Tab(
                                icon: const Icon(Icons.collections_bookmark_outlined),
                                text: tabLabel('All', counts.isEmpty ? null : total),
                              )
                            : Tab(icon: Icon(s.icon), text: tabLabel(s.label, counts[s])),
                      for (final c in collections)
                        Tab(
                          icon: const Icon(Icons.folder_outlined),
                          text: tabLabel(c.name, c.count),
                        ),
                    ],
                  )
                : null,
          ),
          body: prefs.showTabs
              ? TabBarView(
                  children: [
                    for (final s in tabs) StatusListView(status: s),
                    for (final c in collections) StatusListView.collection(c),
                  ],
                )
              : const StatusListView(status: null),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.explore_outlined),
            label: const Text('Browse'),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const BrowseScreen()))
                // You may have added VNs while browsing.
                .then((_) => refreshLibrary(ref)),
          ),
        ),
      ),
    );
  }
}
