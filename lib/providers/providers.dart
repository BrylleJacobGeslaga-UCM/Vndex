import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/app_database.dart';
import '../data/remote/vndb_api.dart';
import '../data/repository/vn_repository.dart';
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

/// Call after adding, moving or removing a VN so every screen reloads.
void refreshLibrary(WidgetRef ref) {
  ref.invalidate(statusListProvider);
  ref.invalidate(statusCountsProvider);
  ref.invalidate(userEntryProvider);
}
