import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vn.dart';
import '../../models/vn_status.dart';
import '../../providers/providers.dart';
import 'collection_picker_sheet.dart';
import 'vn_cover.dart';

/// Opens the "add / move / remove" sheet for a VN.
Future<void> showAddToListSheet(BuildContext context, Vn vn) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => AddToListSheet(vn: vn),
  );
}

/// Bottom sheet: pick which list a VN goes in. The current list is ticked.
class AddToListSheet extends ConsumerWidget {
  const AddToListSheet({super.key, required this.vn});

  final Vn vn;

  /// Removes the VN, then offers "Undo" for a few seconds.
  Future<void> _removeWithUndo(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    // The sheet (and its ref) is gone by the time Undo is tapped,
    // so keep the app-wide container instead.
    final container = ProviderScope.containerOf(context, listen: false);
    final repo = ref.read(vnRepositoryProvider);

    try {
      final removed = await repo.remove(vn.id);
      refreshLibrary(ref);
      navigator.pop();
      messenger.hideCurrentSnackBar();
      final bar = messenger.showSnackBar(SnackBar(
          content: Text('Removed ${vn.title}'),
          duration: const Duration(seconds: 3),
          action: removed == null
              ? null
              : SnackBarAction(
                  label: 'Undo',
                  onPressed: () async {
                    await repo.undoRemove(removed);
                    refreshLibraryIn(container);
                  },
                ),
        ));
      // Newer Flutter keeps snackbars with a button open until tapped,
      // so close it ourselves after 3 seconds — but only if it's still
      // showing (Undo, a swipe or another snackbar may have closed it).
      var open = true;
      bar.closed.whenComplete(() => open = false);
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (open) bar.close();
      });
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not remove: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(userEntryProvider(vn.id)).maybeWhen(
          data: (entry) => entry?.status,
          orElse: () => null,
        );
    final scheme = Theme.of(context).colorScheme;

    Future<void> run(Future<void> Function() action, String message) async {
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      try {
        await action();
        refreshLibrary(ref);
        navigator.pop();
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    }

    final repo = ref.read(vnRepositoryProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  VnCover(vn: vn, width: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      vn.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (final s in VnStatus.values)
              ListTile(
                leading: Icon(s.icon),
                title: Text(s.label),
                selected: s == current,
                trailing: s == current ? const Icon(Icons.check) : null,
                onTap: s == current
                    ? null
                    : () => run(
                          () => repo.setStatus(vn, s),
                          current == null
                              ? 'Added to ${s.label}'
                              : 'Moved to ${s.label}',
                        ),
              ),
            if (current != null) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.collections_bookmark_outlined),
                title: const Text('Collections…'),
                onTap: () {
                  // This sheet's context dies when it closes; open the
                  // picker from the navigator, which stays alive.
                  final nav = Navigator.of(context);
                  nav.pop();
                  showCollectionPicker(nav.context, vn);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: scheme.error),
                title: Text('Remove from lists',
                    style: TextStyle(color: scheme.error)),
                onTap: () => _removeWithUndo(context, ref),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
