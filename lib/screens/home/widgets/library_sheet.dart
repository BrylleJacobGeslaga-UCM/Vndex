import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/library_prefs.dart';
import '../../../providers/providers.dart';

/// Opens the library sheet (Filter · Sort · Display).
/// Every change applies right away and is remembered.
Future<void> showLibrarySheet(BuildContext context, {int initialTab = 0}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: LibrarySheet(initialTab: initialTab),
    ),
  );
}

class LibrarySheet extends ConsumerWidget {
  const LibrarySheet({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      initialIndex: initialTab,
      child: Column(
        children: [
          const SizedBox(height: 8),
          const TabBar(
            tabs: [Tab(text: 'Filter'), Tab(text: 'Sort'), Tab(text: 'Display')],
          ),
          const Expanded(
            child: TabBarView(
              children: [_FilterTab(), _SortTab(), _DisplayTab()],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- Filter ----------------

class _FilterTab extends ConsumerWidget {
  const _FilterTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(settingsProvider.select((s) => s.library));
    final n = ref.read(settingsProvider.notifier);

    Widget tri(String label, TriState value, LibraryPrefs Function(TriState) set) =>
        ListTile(
          leading: Icon(
            value.icon,
            color: value == TriState.any
                ? Theme.of(context).colorScheme.outline
                : value == TriState.exclude
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
          ),
          title: Text(label),
          onTap: () => n.updateLibrary((_) => set(value.next)),
        );

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        tri('Rated', p.filterScored, (v) => p.copyWith(filterScored: v)),
        tri('Has review', p.filterHasReview, (v) => p.copyWith(filterHasReview: v)),
        tri('Released', p.filterReleased, (v) => p.copyWith(filterReleased: v)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            'Tap to cycle: ☐ off → ☑ only these → ☒ hide these',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
          ),
        ),
        if (p.hasActiveFilter)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: TextButton(
                onPressed: () => n.updateLibrary((c) => c.copyWith(
                      filterScored: TriState.any,
                      filterHasReview: TriState.any,
                      filterReleased: TriState.any,
                    )),
                child: const Text('Clear filters'),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------- Sort ----------------

class _SortTab extends ConsumerWidget {
  const _SortTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(settingsProvider.select((s) => s.library));
    final n = ref.read(settingsProvider.notifier);
    final accent = Theme.of(context).colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        for (final s in ListSort.values)
          ListTile(
            // Arrow shows the direction; tap the active sort again to flip it.
            leading: s == p.sort
                ? Icon(
                    p.descending ? Icons.arrow_downward : Icons.arrow_upward,
                    color: accent,
                  )
                : const SizedBox(width: 24),
            title: Text(
              s.label,
              style: s == p.sort ? TextStyle(color: accent) : null,
            ),
            onTap: () => n.updateLibrary(
              (c) => s == c.sort
                  ? c.copyWith(sortReversed: !c.sortReversed)
                  : c.copyWith(sort: s, sortReversed: false),
            ),
          ),
      ],
    );
  }
}

// ---------------- Display ----------------

class _DisplayTab extends ConsumerWidget {
  const _DisplayTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(settingsProvider.select((s) => s.library));
    final n = ref.read(settingsProvider.notifier);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    Widget heading(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(t, style: text.titleSmall),
        );

    Widget check(String label, bool value, LibraryPrefs Function(bool) set,
            {bool enabled = true}) =>
        CheckboxListTile(
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(label),
          value: value,
          enabled: enabled,
          onChanged: (v) => n.updateLibrary((_) => set(v ?? false)),
        );

    final isList = p.display == LibraryDisplay.list;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        heading('Display mode'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in LibraryDisplay.values)
                ChoiceChip(
                  label: Text(d.label),
                  selected: p.display == d,
                  showCheckmark: false,
                  onSelected: (_) => n.updateLibrary((c) => c.copyWith(display: d)),
                ),
            ],
          ),
        ),

        if (p.display.isGrid) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Row(
              children: [
                Expanded(child: Text('Items per row', style: text.titleSmall)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${p.gridColumns}'),
                ),
              ],
            ),
          ),
          Slider(
            value: p.gridColumns.toDouble(),
            min: LibraryPrefs.minColumns.toDouble(),
            max: LibraryPrefs.maxColumns.toDouble(),
            divisions: LibraryPrefs.maxColumns - LibraryPrefs.minColumns,
            label: '${p.gridColumns}',
            onChanged: (v) =>
                n.updateLibrary((c) => c.copyWith(gridColumns: v.round())),
          ),
        ],

        heading('Overlay'),
        check('Your rating', p.showScore, (v) => p.copyWith(showScore: v)),
        check('List badge (All tab)', p.showStatus, (v) => p.copyWith(showStatus: v)),
        check('VNDB rating (list mode)', p.showRating,
            (v) => p.copyWith(showRating: v),
            enabled: isList),

        heading('Tabs'),
        check('Show list tabs', p.showTabs, (v) => p.copyWith(showTabs: v)),
        check('Show number of items', p.showTabCounts,
            (v) => p.copyWith(showTabCounts: v)),
      ],
    );
  }
}
