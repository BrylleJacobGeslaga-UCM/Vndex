import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/app_database.dart';
import '../data/local/settings_store.dart';
import '../data/remote/vndb_api.dart';
import '../data/repository/vn_repository.dart';
import '../models/app_settings.dart';
import '../models/browse_filter.dart';
import '../models/character.dart';
import '../models/user_entry.dart';
import '../models/vn.dart';
import '../models/vn_status.dart';

/// One shared VNDB API client for the whole app.
final vndbApiProvider = Provider<VndbApi>((ref) => VndbApi());

/// The opened database. Real value is supplied in main.dart.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('Overridden in main()'),
);

final vnRepositoryProvider = Provider<VnRepository>(
  (ref) => VnRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(vndbApiProvider),
  ),
);

/// The VNs in one status list.
final statusListProvider =
    FutureProvider.family<List<LibraryEntry>, VnStatus>(
  (ref, status) => ref.watch(vnRepositoryProvider).getList(status),
);

/// Number of VNs per list.
final statusCountsProvider = FutureProvider<Map<VnStatus, int>>(
  (ref) => ref.watch(vnRepositoryProvider).getCounts(),
);

/// Your entry for one VN (null = not in any list).
final userEntryProvider = FutureProvider.family<UserEntry?, String>(
  (ref, vnId) => ref.watch(vnRepositoryProvider).getEntry(vnId),
);

/// Full details of one VN (description, tags) for the detail screen.
final vnDetailsProvider = FutureProvider.family<Vn, String>(
  (ref, vnId) => ref.watch(vnRepositoryProvider).getDetails(vnId),
);

/// Text typed in the home screen's search box (filters all four lists).
final librarySearchProvider =
    NotifierProvider<LibrarySearch, String>(LibrarySearch.new);

class LibrarySearch extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query;
}

/// Characters of one VN (detail screen).
final vnCharactersProvider = FutureProvider.family<List<VnCharacter>, String>(
  (ref, vnId) => ref.watch(vnRepositoryProvider).getCharacters(vnId),
);

/// Your saved Browse filters. Invalidate after saving or deleting one.
final savedSearchesProvider = FutureProvider<List<SavedSearch>>(
  (ref) => ref.watch(vnRepositoryProvider).getSavedSearches(),
);

/// Call after adding, moving or removing a VN so every screen reloads.
void refreshLibrary(WidgetRef ref) {
  ref.invalidate(statusListProvider);
  ref.invalidate(statusCountsProvider);
  ref.invalidate(userEntryProvider);
}

// ---------- Settings ----------

final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => SettingsStore(ref.watch(appDatabaseProvider)),
);

/// Settings loaded at startup. Real value is supplied in main.dart.
final initialSettingsProvider = Provider<AppSettings>(
  (ref) => throw UnimplementedError('Overridden in main()'),
);

/// Current settings. Watch it to react to changes; change with
/// `ref.read(settingsProvider.notifier).update((s) => s.copyWith(...))`.
final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(initialSettingsProvider);

  /// Applies a change right away and saves it in the background.
  void update(AppSettings Function(AppSettings current) change) {
    state = change(state);
    ref.read(settingsStoreProvider).save(state);
  }
}
