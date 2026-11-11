import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/format.dart';
import '../../../data/local/backup_file.dart';
import '../../../data/local/backup_service.dart';
import '../../../data/local/settings_store.dart';
import '../../../providers/providers.dart';
import 'settings_widgets.dart';

/// "Backup" in Data and storage: back up now, restore from a file.
class BackupSection extends ConsumerStatefulWidget {
  const BackupSection({super.key});

  @override
  ConsumerState<BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends ConsumerState<BackupSection> {
  bool _busy = false;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  /// "vndex-backup-2026-11-11.json"
  String _fileName() {
    final d = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return 'vndex-backup-${d.year}-${two(d.month)}-${two(d.day)}.json';
  }

  Future<void> _backUp() async {
    setState(() => _busy = true);
    try {
      final bytes = await ref.read(backupServiceProvider).export();
      final saved = await saveBackupFile(_fileName(), bytes);
      if (!saved) return; // cancelled
      ref
          .read(settingsProvider.notifier)
          .update((s) => s.copyWith(lastBackupAt: DateTime.now()));
      _snack('Backup saved');
    } catch (e) {
      _snack('Could not save backup: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      final bytes = await pickBackupFile();
      if (bytes == null) return; // cancelled

      final Backup backup;
      try {
        backup = Backup.fromBytes(bytes);
      } on BackupException catch (e) {
        _snack(e.message);
        return;
      }

      if (!mounted) return;
      final replace = await _askHow(backup.summary);
      if (replace == null) return; // cancelled

      await ref.read(backupServiceProvider).restore(backup, replace: replace);

      // Reload everything that may have changed.
      refreshLibrary(ref);
      ref.invalidate(savedSearchesProvider);
      if (replace && backup.summary.hasSettings) {
        final restored = await SettingsStore(ref.read(appDatabaseProvider)).load();
        ref.read(settingsProvider.notifier).replaceAll(restored);
      }
      _snack(replace ? 'Backup restored' : 'Backup merged into your library');
    } catch (e) {
      _snack('Could not restore: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Shows what's in the file; returns true = replace, false = merge,
  /// null = cancel.
  Future<bool?> _askHow(BackupSummary sum) {
    final dateStyle = ref.read(settingsProvider).dateStyle;
    final lines = [
      '${sum.entries} VN${sum.entries == 1 ? '' : 's'} with ratings and reviews',
      if (sum.collections > 0) '${sum.collections} collection${sum.collections == 1 ? '' : 's'}',
      if (sum.savedSearches > 0)
        '${sum.savedSearches} saved search${sum.savedSearches == 1 ? '' : 'es'}',
      if (sum.hasSettings) 'Your settings',
    ];

    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        final muted = Theme.of(ctx).colorScheme.outline;
        return AlertDialog(
          title: const Text('Restore backup?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sum.exportedAt != null)
                Text(
                  'Made ${formatDate(sum.exportedAt!, dateStyle)}'
                  '${sum.appVersion != null ? ' · Vndex ${sum.appVersion}' : ''}',
                  style: TextStyle(color: muted),
                ),
              const SizedBox(height: 12),
              for (final l in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $l'),
                ),
              const SizedBox(height: 12),
              Text(
                'Merge adds this to what you have here.\n'
                'Replace deletes everything here first.',
                style: TextStyle(color: muted, fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Replace'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Merge'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final last = settings.lastBackupAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Backup'),
        ListTile(
          leading: const Icon(Icons.backup_outlined),
          title: const Text('Back up now'),
          subtitle: Text(
            last == null
                ? 'Never backed up'
                : 'Last backup: ${formatDate(last, settings.dateStyle)}',
          ),
          trailing: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          enabled: !_busy,
          onTap: _backUp,
        ),
        ListTile(
          leading: const Icon(Icons.settings_backup_restore),
          title: const Text('Restore from backup'),
          subtitle: const Text('Merge into this library or replace it'),
          enabled: !_busy,
          onTap: _restore,
        ),
        const InfoNote(
          'A backup is one .json file with your lists, ratings, reviews, '
          'collections, saved searches and settings. Keep it somewhere safe, '
          'like Google Drive, and back up again after big changes.',
        ),
      ],
    );
  }
}
