import 'package:sembast/sembast.dart';

import '../../models/browse_filter.dart';
import '../../models/character.dart';
import '../../models/user_entry.dart';
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
      });

  /// Remove a VN from your lists completely (entry + cached info).
  Future<void> remove(String vnId) async {
    await _store.transaction((txn) async {
      await _entries.record(vnId).delete(txn);
      await _vns.record(vnId).delete(txn);
    });
  }
}
