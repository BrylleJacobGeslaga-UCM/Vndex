import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/app_database.dart';
import '../data/local/backup_service.dart';
import '../data/local/settings_store.dart';
import '../data/remote/vndb_api.dart';
import '../data/repository/vn_repository.dart';
import '../models/app_settings.dart';
import '../services/home_widget_sync.dart';
import '../models/browse_filter.dart';
import '../models/character.dart';
import '../models/english.dart';
import '../models/quote.dart';
import '../models/user_entry.dart';
import '../models/vn_collection.dart';
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

/// The VNs in one status list. null = all lists combined ("All" tab).
final statusListProvider =
    FutureProvider.family<List<LibraryEntry>, VnStatus?>(
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

/// English availability of one VN (detail screen).
final englishProvider = FutureProvider.family<EnglishAvailability, String>(
  (ref, vnId) => ref.watch(vnRepositoryProvider).getEnglishAvailability(vnId),
);

/// Quotes from one VN (detail screen).
final vnQuotesProvider = FutureProvider.family<List<VnQuote>, String>(
  (ref, vnId) => ref.watch(vnRepositoryProvider).getQuotes(vnId),
);

/// Your saved Browse filters. Invalidate after saving or deleting one.
final savedSearchesProvider = FutureProvider<List<SavedSearch>>(
  (ref) => ref.watch(vnRepositoryProvider).getSavedSearches(),
);

/// Updates the Android home screen widget ("Currently playing").
final homeWidgetSyncProvider = Provider<HomeWidgetSync>(
  (ref) => HomeWidgetSync(
    ref.watch(vnRepositoryProvider),
    () => ref.read(settingsProvider),
  ),
);

/// Call after adding, moving or removing a VN so every screen reloads.
/// Also refreshes the home screen widget.
void refreshLibrary(WidgetRef ref) {
  ref.read(homeWidgetSyncProvider).sync();
  ref.invalidate(statusListProvider);
  ref.invalidate(statusCountsProvider);
  ref.invalidate(userEntryProvider);
  ref.invalidate(collectionsProvider);
  ref.invalidate(collectionEntriesProvider);
  ref.invalidate(vnCollectionsProvider);
}

/// Same, for code that runs after its widget is gone (e.g. a snackbar's
/// Undo button pressed after the sheet closed).
void refreshLibraryIn(ProviderContainer container) {
  container.read(homeWidgetSyncProvider).sync();
  container.invalidate(statusListProvider);
  container.invalidate(statusCountsProvider);
  container.invalidate(userEntryProvider);
  container.invalidate(collectionsProvider);
  container.invalidate(collectionEntriesProvider);
  container.invalidate(vnCollectionsProvider);
}

// ---------- Collections ----------

/// All your collections, in order (they appear as tabs after the lists).
final collectionsProvider = FutureProvider<List<VnCollection>>(
  (ref) => ref.watch(vnRepositoryProvider).getCollections(),
);

/// The VNs in one collection.
final collectionEntriesProvider = FutureProvider.family<List<LibraryEntry>, int>(
  (ref, key) => ref.watch(vnRepositoryProvider).getCollectionEntries(key),
);

/// Which collections one VN is in.
final vnCollectionsProvider = FutureProvider.family<Set<int>, String>(
  (ref, vnId) => ref.watch(vnRepositoryProvider).collectionsFor(vnId),
);

/// Call after creating, renaming, deleting or changing a collection.
void refreshCollections(WidgetRef ref) {
  ref.invalidate(collectionsProvider);
  ref.invalidate(collectionEntriesProvider);
  ref.invalidate(vnCollectionsProvider);
}

// ---------- Settings ----------

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(appDatabaseProvider)),
);

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

  /// After restoring a backup: switch to the restored settings.
  void replaceAll(AppSettings settings) {
    state = settings;
    ref.read(settingsStoreProvider).save(state);
  }

  /// Shortcut for the library sheet: change only the library options.
  void updateLibrary(LibraryPrefs Function(LibraryPrefs current) change) =>
      update((s) => s.copyWith(library: change(s.library)));
}
