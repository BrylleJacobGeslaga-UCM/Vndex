import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vn.dart';
import '../../providers/providers.dart';

/// Asks for a collection name. Returns null if cancelled or empty.
Future<String?> askCollectionName(
  BuildContext context, {
  String title = 'New collection',
  String initial = '',
  String action = 'Create',
}) async {
  final controller = TextEditingController(text: initial);
  final name = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'e.g. Favorites'),
        onSubmitted: (v) => Navigator.pop(ctx, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: Text(action),
        ),
      ],
    ),
  );
  controller.dispose();
  final trimmed = name?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}

/// Bottom sheet with a checkbox per collection, plus "New collection".
Future<void> showCollectionPicker(BuildContext context, Vn vn) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => CollectionPickerSheet(vn: vn),
  );
}

class CollectionPickerSheet extends ConsumerWidget {
  const CollectionPickerSheet({super.key, required this.vn});

  final Vn vn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(collectionsProvider);
    final inThese = ref.watch(vnCollectionsProvider(vn.id)).maybeWhen(
          data: (k) => k,
          orElse: () => const <int>{},
        );
    final repo = ref.read(vnRepositoryProvider);

    Future<void> create() async {
      final name = await askCollectionName(context);
      if (name == null) return;
      final key = await repo.createCollection(name);
      await repo.setInCollection(key, vn.id, true); // add this VN right away
      refreshCollections(ref);
    }

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('Collections', style: Theme.of(context).textTheme.titleMedium),
            ),
            Flexible(
              child: async.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Could not load collections:\n$e',
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                      TextButton(
                        onPressed: () => ref.invalidate(collectionsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (collections) => collections.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Row(
                          children: [
                            Icon(Icons.folder_off_outlined,
                                color: Theme.of(context).colorScheme.outline),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No collections yet. Make one below for favorites, '
                                'recommendations, a studio you love…',
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.outline),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          for (final c in collections)
                            CheckboxListTile(
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(c.name),
                              subtitle: Text('${c.count} VN${c.count == 1 ? '' : 's'}'),
                              value: inThese.contains(c.key),
                              onChanged: (v) async {
                                await repo.setInCollection(c.key, vn.id, v ?? false);
                                refreshCollections(ref);
                              },
                            ),
                        ],
                      ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('New collection'),
              onTap: create,
            ),
          ],
        ),
      ),
    );
  }
}
