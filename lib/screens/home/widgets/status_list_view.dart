import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/add_to_list_sheet.dart';
import '../../../models/vn_status.dart';
import '../../../providers/providers.dart';
import '../../detail/detail_screen.dart';
import '../../search/widgets/vn_result_tile.dart';
import 'empty_list.dart';

/// The contents of one tab: your VNs in that status, newest change first.
/// Tap a VN for details; long-press to quickly move or remove it.
class StatusListView extends ConsumerWidget {
  const StatusListView({super.key, required this.status});

  final VnStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(statusListProvider(status));

    return list.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('Could not load list:\n$e', textAlign: TextAlign.center),
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) return EmptyList(status: status);

        return ListView.separated(
          // Leave room so the last item isn't hidden behind the button.
          padding: const EdgeInsets.only(bottom: 88),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 92),
          itemBuilder: (context, i) {
            final vn = entries[i].vn;
            return VnResultTile(
              vn: vn,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => DetailScreen(vn: vn)),
              ),
              onLongPress: () => showAddToListSheet(context, vn),
            );
          },
        );
      },
    );
  }
}
