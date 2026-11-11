import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/collection_picker_sheet.dart';
import '../../models/vn_collection.dart';
import '../../providers/providers.dart';
import 'widgets/settings_widgets.dart';

/// Create, rename, reorder (drag) and delete collections.
class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(collectionsProvider);
    final repo = ref.read(vnRepositoryProvider);
    final error = Theme.of(context).colorScheme.error;

    Future<void> create() async {
      final name = await askCollectionName(context);
      if (name == null) return;
      await repo.createCollection(name);
      refreshCollections(ref);
    }

    Future<void> rename(VnCollection c) async {
      final name = await askCollectionName(
        context,
        title: 'Rename collection',
        initial: c.name,
        action: 'Save',
      );
      if (name == null) return;
      await repo.renameCollection(c.key, name);
      refreshCollections(ref);
    }

    Future<void> delete(VnCollection c) async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Delete "${c.name}"?'),
          content: const Text('The VNs stay in your lists. Only the collection is removed.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      await repo.deleteCollection(c.key);
      refreshCollections(ref);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Collections')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New'),
        onPressed: create,
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load collections:\n$e')),
        data: (list) {
          if (list.isEmpty) {
            return const InfoNote(
              'Collections are your own groups next to the four lists, like '
              'Favorites or Recommend to friends. A VN can be in several.\n\n'
              'Add VNs from a VN page (Collections button) or by long-pressing '
              'a VN in your lists.',
            );
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: list.length,
            onReorder: (from, to) async {
              final keys = [for (final c in list) c.key];
              if (to > from) to -= 1;
              keys.insert(to, keys.removeAt(from));
              await repo.reorderCollections(keys);
              refreshCollections(ref);
            },
            itemBuilder: (_, i) {
              final c = list[i];
              return ListTile(
                key: ValueKey(c.key),
                leading: ReorderableDragStartListener(
                  index: i,
                  child: const Icon(Icons.drag_handle),
                ),
                title: Text(c.name),
                subtitle: Text('${c.count} VN${c.count == 1 ? '' : 's'}'),
                onTap: () => rename(c),
                trailing: IconButton(
                  tooltip: 'Delete',
                  icon: Icon(Icons.delete_outline, color: error),
                  onPressed: () => delete(c),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
