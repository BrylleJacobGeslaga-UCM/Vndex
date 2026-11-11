import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/format.dart';
import '../../../core/widgets/add_to_list_sheet.dart';
import '../../../core/widgets/vn_result_tile.dart';
import '../../../models/library_prefs.dart';
import '../../../models/user_entry.dart';
import '../../../models/vn_collection.dart';
import '../../../models/vn_status.dart';
import '../../../providers/providers.dart';
import '../../detail/detail_screen.dart';
import 'empty_list.dart';
import 'library_grid.dart';

/// The contents of one tab: your VNs in that status, every status when
/// [status] is null (the "All" tab), or one of your collections when
/// [collection] is set. Filtered, sorted and displayed as set in the
/// library sheet, plus the home screen's search box.
class StatusListView extends ConsumerWidget {
  const StatusListView({super.key, required this.status, this.collection});

  /// A collection tab instead.
  const StatusListView.collection(VnCollection this.collection, {super.key})
      : status = null;

  /// null = All (unless [collection] is set).
  final VnStatus? status;
  final VnCollection? collection;

  String get _tabName => collection?.name ?? status?.label ?? 'All';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = collection != null
        ? ref.watch(collectionEntriesProvider(collection!.key))
        : ref.watch(statusListProvider(status));
    final prefs = ref.watch(settingsProvider.select((s) => s.library));
    final query = ref.watch(librarySearchProvider).trim().toLowerCase();

    void openDetail(LibraryEntry e) => Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => DetailScreen(vn: e.vn)))
        // Score/note may have changed on the detail page.
        .then((_) => refreshLibrary(ref));

    return list.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('Could not load list:\n$e', textAlign: TextAlign.center),
        ),
      ),
      data: (all) {
        if (all.isEmpty) {
          return EmptyList(status: status, collectionName: collection?.name);
        }

        final entries = sortEntries(
          filterEntries(all, query, prefs),
          prefs.sort,
          descending: prefs.descending,
        );
        if (entries.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                query.isNotEmpty
                    ? 'No matches for "$query" in $_tabName'
                    : 'No VNs match your filters',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
            ),
          );
        }

        // All and collections mix lists, so they show which list each VN is in.
        final showStatus = status == null && prefs.showStatus;

        if (prefs.display.isGrid) {
          return LibraryGrid(
            entries: entries,
            prefs: prefs,
            showStatus: showStatus,
            onTap: openDetail,
            onLongPress: (e) => showAddToListSheet(context, e.vn),
          );
        }

        return ListView.separated(
          // Leave room so the last item isn't hidden behind the button.
          padding: const EdgeInsets.only(bottom: 88),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 92),
          itemBuilder: (context, i) {
            final e = entries[i];
            final score = prefs.showScore ? e.entry.score : null;

            // "All" shows which list each VN is in, top right, above the score.
            final badges = [
              if (showStatus) _StatusBadge(e.entry.status),
              if (score != null) _ScoreBadge(score),
            ];

            return VnResultTile(
              vn: e.vn,
              showRating: prefs.showRating,
              trailing: badges.isEmpty
                  ? null
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var b = 0; b < badges.length; b++) ...[
                          if (b > 0) const SizedBox(height: 6),
                          badges[b],
                        ],
                      ],
                    ),
              onTap: () => openDetail(e),
              onLongPress: () => showAddToListSheet(context, e.vn),
            );
          },
        );
      },
    );
  }
}

/// Search text + the Filter tab's checkboxes.
List<LibraryEntry> filterEntries(
  List<LibraryEntry> all,
  String query,
  LibraryPrefs prefs,
) {
  final today = DateTime.now().toIso8601String().substring(0, 10);

  bool isReleased(LibraryEntry e) {
    final r = e.vn.released;
    return r != null && r != 'TBA' && r.compareTo(today) <= 0;
  }

  return [
    for (final e in all)
      if ((query.isEmpty ||
              e.vn.title.toLowerCase().contains(query) ||
              (e.vn.altTitle?.toLowerCase().contains(query) ?? false)) &&
          prefs.filterScored.allows(e.entry.score != null) &&
          prefs.filterHasReview.allows(e.entry.review != null) &&
          prefs.filterReleased.allows(isReleased(e)))
        e,
  ];
}

/// Returns a sorted copy. Missing values (no score, no rating, TBA) always
/// go last; ties fall back to title A–Z so the order is stable.
List<LibraryEntry> sortEntries(
  List<LibraryEntry> entries,
  ListSort sort, {
  required bool descending,
}) {
  final dir = descending ? -1 : 1;

  int byTitle(LibraryEntry a, LibraryEntry b) =>
      a.vn.title.toLowerCase().compareTo(b.vn.title.toLowerCase());

  int nullsLast(Comparable<dynamic>? a, Comparable<dynamic>? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return dir * a.compareTo(b);
  }

  String? releaseKey(LibraryEntry e) {
    final r = e.vn.released;
    return (r == null || r == 'TBA') ? null : r; // "2009-10-15" sorts as text
  }

  int compare(LibraryEntry a, LibraryEntry b) {
    final c = switch (sort) {
      ListSort.updated => dir * a.entry.updatedAt.compareTo(b.entry.updatedAt),
      ListSort.title => dir * byTitle(a, b),
      ListSort.score => nullsLast(a.entry.score, b.entry.score),
      ListSort.rating => nullsLast(a.vn.rating, b.vn.rating),
      ListSort.added => dir * a.entry.addedAt.compareTo(b.entry.addedAt),
      ListSort.released => nullsLast(releaseKey(a), releaseKey(b)),
    };
    return c != 0 ? c : byTitle(a, b);
  }

  return [...entries]..sort(compare);
}

/// Which list a VN is in, as a colored pill (used in the "All" tab).
class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);

  final VnStatus status;

  @override
  Widget build(BuildContext context) {
    final c = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: c),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c),
          ),
        ],
      ),
    );
  }
}

/// Your rating as a small pill, in stars out of 5, e.g. "★ 4.5".
class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge(this.score);

  final int score;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 14, color: scheme.onPrimaryContainer),
          const SizedBox(width: 2),
          Text(
            formatStars(score),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
