import 'dart:convert';
import 'dart:typed_data';

import 'package:sembast/sembast.dart';

import '../../core/constants.dart';
import 'app_database.dart';

/// Thrown when a file isn't a Vndex backup (or is from a newer version).
class BackupException implements Exception {
  const BackupException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// What a backup file contains, shown before restoring.
class BackupSummary {
  const BackupSummary({
    required this.entries,
    required this.collections,
    required this.savedSearches,
    required this.hasSettings,
    this.exportedAt,
    this.appVersion,
  });

  final int entries;
  final int collections;
  final int savedSearches;
  final bool hasSettings;
  final DateTime? exportedAt;
  final String? appVersion;
}

/// A parsed backup file, ready to restore.
class Backup {
  Backup._(this._json);

  final Map<String, Object?> _json;

  /// Bump if the file layout changes; older apps refuse newer files.
  static const int formatVersion = 1;

  List<Map<String, Object?>> _list(String key) => [
        for (final v in (_json[key] as List<Object?>?) ?? const [])
          if (v is Map) v.cast<String, Object?>(),
      ];

  List<Map<String, Object?>> get vns => _list('vns');
  List<Map<String, Object?>> get entries => _list('entries');
  List<Map<String, Object?>> get collections => _list('collections');
  List<Map<String, Object?>> get savedSearches => _list('saved_searches');
  Map<String, Object?>? get settings =>
      (_json['settings'] as Map?)?.cast<String, Object?>();

  BackupSummary get summary => BackupSummary(
        entries: entries.length,
        collections: collections.length,
        savedSearches: savedSearches.length,
        hasSettings: settings != null,
        exportedAt: DateTime.tryParse(_json['exported_at'] as String? ?? ''),
        appVersion: _json['app_version'] as String?,
      );

  /// Reads a file's bytes. Throws [BackupException] if it isn't usable.
  factory Backup.fromBytes(Uint8List bytes) {
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } catch (_) {
      throw const BackupException('This file isn\'t a Vndex backup.');
    }
    if (decoded is! Map || decoded['app'] != 'vndex') {
      throw const BackupException('This file isn\'t a Vndex backup.');
    }
    final format = (decoded['format'] as num?)?.toInt() ?? 0;
    if (format > formatVersion) {
      throw const BackupException(
        'This backup is from a newer version of Vndex. Update the app first.',
      );
    }
    return Backup._(decoded.cast<String, Object?>());
  }
}

/// Exports everything to one JSON file and restores it again.
class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  Database get _store => _db.db;

  /// The whole library as UTF-8 JSON bytes.
  Future<Uint8List> export() async {
    final vns = await AppDatabase.vnStore.find(_store);
    final entries = await AppDatabase.entryStore.find(_store);
    final collections = await AppDatabase.collectionStore.find(_store);
    final saved = await AppDatabase.savedSearchStore.find(_store);
    final settings = await AppDatabase.settingsStore.record('app').get(_store);

    final json = {
      'app': 'vndex',
      'format': Backup.formatVersion,
      'app_version': AppConstants.appVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'vns': [for (final r in vns) r.value],
      'entries': [for (final r in entries) r.value],
      'collections': [
        for (final r in collections)
          {
            'name': r.value['name'],
            'order': r.value['order'],
            'vn_ids': r.value['vn_ids'],
          },
      ],
      'saved_searches': [
        for (final r in saved) {'name': r.value['name'], 'filter': r.value['filter']},
      ],
      if (settings != null) 'settings': settings,
    };

    // Indented so the file is readable if you open it.
    return Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(json)),
    );
  }

  /// Restores a backup.
  ///
  /// [replace] true: wipe everything here first, then restore exactly what's
  /// in the backup, settings included.
  /// [replace] false (merge): keep what's here; VNs in the backup overwrite
  /// the same VNs here, collections with the same name are combined, and
  /// saved searches are added if the name is new. Settings are left alone.
  Future<void> restore(Backup backup, {required bool replace}) async {
    final vnStore = AppDatabase.vnStore;
    final entryStore = AppDatabase.entryStore;
    final collStore = AppDatabase.collectionStore;
    final savedStore = AppDatabase.savedSearchStore;

    await _store.transaction((txn) async {
      if (replace) {
        await vnStore.delete(txn);
        await entryStore.delete(txn);
        await collStore.delete(txn);
        await savedStore.delete(txn);
      }

      for (final v in backup.vns) {
        final id = v['id'];
        if (id is String) await vnStore.record(id).put(txn, v, merge: !replace);
      }
      for (final e in backup.entries) {
        final id = e['vn_id'];
        if (id is String) await entryStore.record(id).put(txn, e);
      }

      // Collections: combine with a same-named one, otherwise add at the end.
      final List<RecordSnapshot<int, Map<String, Object?>>> existing =
          replace ? [] : await collStore.find(txn);
      var nextOrder = existing.length;
      for (final c in backup.collections) {
        final name = c['name'];
        if (name is! String) continue;
        final ids = [
          for (final id in (c['vn_ids'] as List<Object?>?) ?? const [])
            if (id is String) id,
        ];

        final match = existing.where(
          (r) => (r.value['name'] as String?)?.toLowerCase() == name.toLowerCase(),
        );
        if (match.isNotEmpty) {
          final rec = match.first;
          final merged = [
            ...((rec.value['vn_ids'] as List<Object?>?) ?? const []).whereType<String>(),
          ];
          for (final id in ids) {
            if (!merged.contains(id)) merged.add(id);
          }
          await collStore.record(rec.key).update(txn, {'vn_ids': merged});
        } else {
          await collStore.add(txn, {
            'name': name,
            'vn_ids': ids,
            'order': replace ? ((c['order'] as num?)?.toInt() ?? nextOrder) : nextOrder,
            'created_at': DateTime.now().millisecondsSinceEpoch,
          });
          nextOrder++;
        }
      }

      // Saved searches: skip names you already have.
      final savedNames = replace
          ? <String>{}
          : {
              for (final r in await savedStore.find(txn))
                (r.value['name'] as String? ?? '').toLowerCase(),
            };
      for (final s in backup.savedSearches) {
        final name = s['name'];
        if (name is! String || savedNames.contains(name.toLowerCase())) continue;
        await savedStore.add(txn, {'name': name, 'filter': s['filter']});
      }

      if (replace && backup.settings != null) {
        await AppDatabase.settingsStore.record('app').put(txn, backup.settings!);
      }
    });
  }
}
