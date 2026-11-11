import 'package:sembast/sembast.dart';

import '../../models/browse_filter.dart';
import '../../models/character.dart';
import '../../models/english.dart';
import '../../models/quote.dart';
import '../../models/user_entry.dart';
import '../../models/vn_collection.dart';
import '../../models/vn.dart';
import '../../models/vn_status.dart';
import '../local/app_database.dart';
import '../remote/vndb_api.dart';

/// The only thing screens talk to for VN data.
/// Search goes to VNDB; your lists live in the local database.
class VnRepository {
  VnRepository(this._db, this._api);

  final AppDatabase _db;
  final VndbApi _api;

  Database get _store => _db.db;
  final _vns = AppDatabase.vnStore;
  final _entries = AppDatabase.entryStore;
  final _saved = AppDatabase.savedSearchStore;
  final _collections = AppDatabase.collectionStore;

  // ---------- VNDB ----------

  Future<List<Vn>> search(String query) => _api.searchVn(query);

  /// Browse VNDB with a filter. See [BrowseFilter.toVndbFilters].
  Future<VnPage> browse({
    required List<Object> filters,
    required String sort,
    required bool reverse,
    int page = 1,
  }) =>
      _api.browse(filters: filters, sort: sort, reverse: reverse, page: page);

  /// Characters of a VN, spoilers removed, most important first.
  Future<List<VnCharacter>> getCharacters(String vnId) async {
    final list = await _api.getCharacters(vnId);
    list.sort((a, b) {
      final r = a.role.index.compareTo(b.role.index);
      return r != 0 ? r : a.name.compareTo(b.name);
    });
    return list;
  }

  /// Whether a VN is playable in English (detail screen).
  Future<EnglishAvailability> getEnglishAvailability(String vnId) =>
      _api.getEnglishAvailability(vnId);

  /// Quotes from a VN (detail screen).
  Future<List<VnQuote>> getQuotes(String vnId) => _api.getQuotes(vnId);

  /// Tag name lookup for the filter sheet.
  Future<List<TagRef>> searchTags(String query) => _api.searchTags(query);

  /// Full details (description, tags) for the detail screen.
  /// Fresh from VNDB when online; falls back to the saved copy when offline.
  /// If the VN is in your lists, the fresh details are saved for next time.
  Future<Vn> getDetails(String id) async {
    try {
      final vn = await _api.getVnDetails(id);
      if (vn == null) throw const VndbException('This VN no longer exists on VNDB.');

      if (await _entries.record(id).exists(_store)) {
        final now = DateTime.now().millisecondsSinceEpoch;
        await _vns.record(id).put(_store, vn.toDb(fetchedAt: now), merge: true);
      }
      return vn;
    } on VndbException {
      final cached = await _vns.record(id).get(_store);
      if (cached != null) return Vn.fromDb(cached);
      rethrow;
    }
  }

  // ---------- Your lists ----------

  /// VNs in one list, most recently changed first.
  /// [status] null = every list combined (the "All" tab).
  Future<List<LibraryEntry>> getList(VnStatus? status) async {
    final entries = await _entries.find(
      _store,
      finder: Finder(
        filter: status == null ? null : Filter.equals('status', status.dbValue),
        sortOrders: [SortOrder('updated_at', false)], // false = newest first
      ),
    );

    // Fetch the matching VN records in one go.
    final vnRows = await _vns.records(entries.map((e) => e.key)).get(_store);

    return [
      for (var i = 0; i < entries.length; i++)
        if (vnRows[i] != null)
          LibraryEntry(
            vn: Vn.fromDb(vnRows[i]!),
            entry: UserEntry.fromDb(entries[i].value),
          ),
    ];
  }

  /// How many VNs are in each list (for the tab labels).
  Future<Map<VnStatus, int>> getCounts() async {
    return {
      for (final s in VnStatus.values)
        s: await _entries.count(
          _store,
          filter: Filter.equals('status', s.dbValue),
        ),
    };
  }

  /// Your entry for a VN, or null if it's not in any list.
  Future<UserEntry?> getEntry(String vnId) async {
    final row = await _entries.record(vnId).get(_store);
    return row == null ? null : UserEntry.fromDb(row);
  }

  /// Add a VN to a list, or move it to another list.
  /// Also caches the VN's info locally so the lists work offline.
  Future<void> setStatus(Vn vn, VnStatus status) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await _store.transaction((txn) async {
      // merge: true keeps fields we don't send (e.g. a description fetched
      // later on the detail screen).
      await _vns.record(vn.id).put(txn, vn.toDb(fetchedAt: now), merge: true);

      final entryRef = _entries.record(vn.id);
      final existing = await entryRef.get(txn);

      if (existing == null) {
        await entryRef.put(txn, {
          'vn_id': vn.id,
          'status': status.dbValue,
          'started_at': status == VnStatus.playing ? now : null,
          'finished_at': status == VnStatus.finished ? now : null,
          'added_at': now,
          'updated_at': now,
        });
      } else {
        final old = UserEntry.fromDb(existing);
        await entryRef.update(txn, {
          'status': status.dbValue,
          'updated_at': now,
          // Only stamp dates the first time; keep the original otherwise.
          if (status == VnStatus.playing && old.startedAt == null)
            'started_at': now,
          if (status == VnStatus.finished && old.finishedAt == null)
            'finished_at': now,
        });
      }
    });
  }

  /// Your rating, 1–10 (half stars). Pass null to clear it.
  /// Doesn't change `updated_at`, so editing doesn't reorder your lists.
  Future<void> setScore(String vnId, int? score) =>
      _entries.record(vnId).update(_store, {'score': score});

  /// Save your review. Empty text deletes it.
  Future<void> setReview(String vnId, String text, {required bool spoiler}) {
    final trimmed = text.trim();
    return _entries.record(vnId).update(_store, {
      'review': trimmed.isEmpty ? null : trimmed,
      'review_spoiler': trimmed.isEmpty ? false : spoiler,
      'reviewed_at': trimmed.isEmpty ? null : DateTime.now().millisecondsSinceEpoch,
      'progress_note': null, // old field, replaced by review
    });
  }

  // ---------- Saved searches ----------

  Future<List<SavedSearch>> getSavedSearches() async {
    final rows = await _saved.find(_store, finder: Finder(sortOrders: [SortOrder('name')]));
    return [
      for (final r in rows)
        SavedSearch(
          key: r.key,
          name: r.value['name'] as String,
          filter: BrowseFilter.fromJson(
            r.value['filter'] as Map<String, Object?>,
          ),
        ),
    ];
  }

  Future<void> saveSearch(String name, BrowseFilter filter) =>
      _saved.add(_store, {'name': name, 'filter': filter.toJson()});

  Future<void> deleteSavedSearch(int key) => _saved.record(key).delete(_store);

  /// Delete all saved searches.
  Future<void> clearSavedSearches() => _saved.delete(_store);

  /// Delete your lists, cached VN info and saved searches.
  /// Settings are kept.
  Future<void> deleteAllData() => _store.transaction((txn) async {
        await _entries.delete(txn);
        await _vns.delete(txn);
        await _saved.delete(txn);
        await _collections.delete(txn);
      });

  /// Remove a VN from your lists completely (entry + cached info).
  /// Also takes it out of every collection.
  /// Returns what was removed, so it can be put back with [undoRemove].
  Future<RemovedVn?> remove(String vnId) async {
    RemovedVn? removed;
    await _store.transaction((txn) async {
      final entry = await _entries.record(vnId).get(txn);
      final vn = await _vns.record(vnId).get(txn);

      final holding = await _collections.find(
        txn,
        finder: Finder(filter: Filter.equals('vn_ids', vnId, anyInList: true)),
      );
      final positions = <int, int>{};
      for (final c in holding) {
        final ids = [...(c.value['vn_ids'] as List<Object?>).cast<String>()];
        positions[c.key] = ids.indexOf(vnId);
        ids.remove(vnId);
        await _collections.record(c.key).update(txn, {'vn_ids': ids});
      }

      await _entries.record(vnId).delete(txn);
      await _vns.record(vnId).delete(txn);

      if (entry != null && vn != null) {
        removed = RemovedVn._(vnId, entry, vn, positions);
      }
    });
    return removed;
  }

  /// Puts a removed VN back exactly as it was: list, rating, review, dates
  /// and its place in each collection.
  Future<void> undoRemove(RemovedVn r) => _store.transaction((txn) async {
        await _vns.record(r.vnId).put(txn, r._vn);
        await _entries.record(r.vnId).put(txn, r._entry);
        for (final e in r._collectionPositions.entries) {
          final row = await _collections.record(e.key).get(txn);
          if (row == null) continue; // collection was deleted meanwhile
          final ids = [...((row['vn_ids'] as List<Object?>?) ?? const []).cast<String>()];
          if (ids.contains(r.vnId)) continue;
          ids.insert(e.value.clamp(0, ids.length), r.vnId);
          await _collections.record(e.key).update(txn, {'vn_ids': ids});
        }
      });

  // ---------- Collections ----------

  /// All collections, in your chosen order.
  Future<List<VnCollection>> getCollections() async {
    // Plain find + sort in Dart: works the same on a brand-new, empty store
    // and on records missing an 'order' field.
    final rows = await _collections.find(_store);
    final list = [for (final r in rows) VnCollection.fromDb(r.key, r.value)];
    list.sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      return byOrder != 0 ? byOrder : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  /// Creates a collection at the end and returns its key.
  Future<int> createCollection(String name) async {
    final count = await _collections.count(_store);
    return _collections.add(_store, {
      'name': name.trim(),
      'vn_ids': <String>[],
      'order': count,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> renameCollection(int key, String name) =>
      _collections.record(key).update(_store, {'name': name.trim()});

  /// Deletes the collection only; the VNs stay in your lists.
  Future<void> deleteCollection(int key) => _collections.record(key).delete(_store);

  /// Saves a new order after dragging collections around.
  Future<void> reorderCollections(List<int> keysInOrder) =>
      _store.transaction((txn) async {
        for (var i = 0; i < keysInOrder.length; i++) {
          await _collections.record(keysInOrder[i]).update(txn, {'order': i});
        }
      });

  /// Adds or removes one VN. Newest additions go first.
  Future<void> setInCollection(int key, String vnId, bool inIt) =>
      _store.transaction((txn) async {
        final row = await _collections.record(key).get(txn);
        if (row == null) return;
        final ids = [...((row['vn_ids'] as List<Object?>?) ?? const []).cast<String>()];
        ids.remove(vnId);
        if (inIt) ids.insert(0, vnId);
        await _collections.record(key).update(txn, {'vn_ids': ids});
      });

  /// Keys of the collections a VN is in.
  Future<Set<int>> collectionsFor(String vnId) async {
    final keys = await _collections.findKeys(
      _store,
      finder: Finder(filter: Filter.equals('vn_ids', vnId, anyInList: true)),
    );
    return keys.toSet();
  }

  /// The VNs in one collection, with your entries (same shape as a list).
  Future<List<LibraryEntry>> getCollectionEntries(int key) async {
    final row = await _collections.record(key).get(_store);
    if (row == null) return const [];
    final ids = ((row['vn_ids'] as List<Object?>?) ?? const []).cast<String>();

    final entries = await _entries.records(ids).get(_store);
    final vns = await _vns.records(ids).get(_store);
    return [
      for (var i = 0; i < ids.length; i++)
        if (entries[i] != null && vns[i] != null)
          LibraryEntry(vn: Vn.fromDb(vns[i]!), entry: UserEntry.fromDb(entries[i]!)),
    ];
  }
}

/// Snapshot of a removed VN, kept briefly for "Undo".
class RemovedVn {
  RemovedVn._(this.vnId, this._entry, this._vn, this._collectionPositions);

  final String vnId;
  final Map<String, Object?> _entry;
  final Map<String, Object?> _vn;
  final Map<int, int> _collectionPositions; // collection key -> index
}
