import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vn_status.dart';
import '../../providers/providers.dart';
import 'widgets/settings_widgets.dart';

/// What's stored on this device, and ways to clear it.
class DataScreen extends ConsumerWidget {
  const DataScreen({super.key});

  Future<bool> _confirm(BuildContext context, String title, String body) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(statusCountsProvider).maybeWhen(
          data: (c) => c,
          orElse: () => const <VnStatus, int>{},
        );
    final saved = ref.watch(savedSearchesProvider).maybeWhen(
          data: (s) => s.length,
          orElse: () => 0,
        );
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    final repo = ref.read(vnRepositoryProvider);
    final error = Theme.of(context).colorScheme.error;

    void done(String msg) => ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));

    return Scaffold(
      appBar: AppBar(title: const Text('Data and storage')),
      body: ListView(
        children: [
          const SectionHeader('Your library'),
          ListTile(
            title: const Text('VNs in your lists'),
            subtitle: Text([
              for (final s in VnStatus.values) '${s.label}: ${counts[s] ?? 0}',
            ].join(' · ')),
            trailing: Text('$total', style: Theme.of(context).textTheme.titleLarge),
          ),
          ListTile(
            title: const Text('Saved searches'),
            trailing: Text('$saved', style: Theme.of(context).textTheme.titleLarge),
          ),

          const SectionHeader('Clear data'),
          ListTile(
            leading: const Icon(Icons.bookmark_remove_outlined),
            title: const Text('Clear saved searches'),
            enabled: saved > 0,
            onTap: () async {
              if (!await _confirm(context, 'Clear saved searches?',
                  'All $saved saved searches will be deleted.')) {
                return;
              }
              await repo.clearSavedSearches();
              ref.invalidate(savedSearchesProvider);
              done('Saved searches cleared');
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: error),
            title: Text('Delete all data', style: TextStyle(color: error)),
            subtitle: const Text('Your lists, ratings, reviews and saved searches'),
            onTap: () async {
              if (!await _confirm(
                context,
                'Delete all data?',
                'This removes all $total VNs from your lists, with their ratings '
                    'and reviews, plus your saved searches. It cannot be undone. '
                    'Settings are kept.',
              )) {
                return;
              }
              await repo.deleteAllData();
              refreshLibrary(ref);
              ref.invalidate(savedSearchesProvider);
              done('All data deleted');
            },
          ),
          const InfoNote(
            'Everything is stored only on this device. Chrome and your phone '
            'each keep their own separate data.',
          ),
        ],
      ),
    );
  }
}
