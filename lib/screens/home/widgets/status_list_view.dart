import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/add_to_list_sheet.dart';
import '../../../core/widgets/vn_result_tile.dart';
import '../../../models/app_settings.dart';
import '../../../models/user_entry.dart';
import '../../../models/vn_status.dart';
import '../../../providers/providers.dart';
import '../../detail/detail_screen.dart';
import 'empty_list.dart';

/// The contents of one tab: your VNs in that status, sorted and filtered
/// by the home screen's sort button and search box.
/// Tap a VN for details; long-press to quickly move or remove it.
class StatusListView extends ConsumerWidget {
  const StatusListView({super.key, required this.status});

  final VnStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(statusListProvider(status));
    final sort = ref.watch(settingsProvider.select((s) => s.listSort));
    final query = ref.watch(librarySearchProvider).trim().toLowerCase();

    return list.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('Could not load list:\n$e', textAlign: TextAlign.center),
        ),
      ),
      data: (all) {
        if (all.isEmpty) return EmptyList(status: status);

        final entries = sortEntries(filterEntries(all, query), sort);
        if (entries.isEmpty) {
          return Center(
            child: Text(
              'No matches for "$query" in ${status.label}',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          );
        }

        return ListView.separated(
          // Leave room so the last item isn't hidden behind the button.
          padding: const EdgeInsets.only(bottom: 88),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 92),
          itemBuilder: (context, i) {
            final e = entries[i];
            final note = e.entry.progressNote;
            return VnResultTile(
              vn: e.vn,
              trailing: e.entry.score == null ? null : _ScoreBadge(e.entry.score!),
              footer: note == null ? null : _NoteLine(note),
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => DetailScreen(vn: e.vn)))
                  // Score/note may have changed on the detail page.
                  .then((_) => ref.invalidate(statusListProvider)),
              onLongPress: () => showAddToListSheet(context, e.vn),
            );
          },
        );
      },
    );
  }
}

/// Keeps entries whose title or original title contains [query].
List<LibraryEntry> filterEntries(List<LibraryEntry> all, String query) {
  if (query.isEmpty) return all;
  return [
    for (final e in all)
      if (e.vn.title.toLowerCase().contains(query) ||
          (e.vn.altTitle?.toLowerCase().contains(query) ?? false))
        e,
  ];
}

/// Returns a sorted copy. Missing values (no score, no rating, TBA) go last;
/// ties fall back to title so the order is stable.
List<LibraryEntry> sortEntries(List<LibraryEntry> entries, ListSort sort) {
  int byTitle(LibraryEntry a, LibraryEntry b) =>
      a.vn.title.toLowerCase().compareTo(b.vn.title.toLowerCase());

  /// Highest first, nulls last.
  int desc(Comparable<dynamic>? a, Comparable<dynamic>? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return b.compareTo(a);
  }

  String? releaseKey(LibraryEntry e) {
    final r = e.vn.released;
    return (r == null || r == 'TBA') ? null : r; // "2009-10-15" sorts as text
  }

  int compare(LibraryEntry a, LibraryEntry b) {
    final c = switch (sort) {
      ListSort.updated => b.entry.updatedAt.compareTo(a.entry.updatedAt),
      ListSort.title => 0,
      ListSort.score => desc(a.entry.score, b.entry.score),
      ListSort.rating => desc(a.vn.rating, b.vn.rating),
      ListSort.added => b.entry.addedAt.compareTo(a.entry.addedAt),
      ListSort.released => desc(releaseKey(a), releaseKey(b)),
    };
    return c != 0 ? c : byTitle(a, b);
  }

  return [...entries]..sort(compare);
}

/// Your score as a small pill, e.g. "★ 8".
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
            '$score',
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

/// Your progress note, one line, under the VN info.
class _NoteLine extends StatelessWidget {
  const _NoteLine(this.note);

  final String note;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.edit_note, size: 16, color: scheme.primary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            note,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}
