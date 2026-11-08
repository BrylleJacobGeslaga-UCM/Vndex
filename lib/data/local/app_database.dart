import 'package:sembast/sembast.dart';

import '../../core/constants.dart';
import 'db_factory.dart';

/// The local database (sembast — pure Dart, works on Android and web).
///
/// sembast stores records in "stores" instead of SQL tables. Each record is a
/// key plus a map of fields, and the field names match the plan:
///
///  * `vn`         key = VNDB id ("v17"). Cached VNDB info, so lists work
///                 offline.
///  * `user_entry` key = VNDB id. YOUR data: status, dates, score, notes.
///
/// They're separate so refreshing VNDB info never wipes your progress.
/// Tags will be saved inside the `vn` record in Step 6.
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static final vnStore = stringMapStoreFactory.store('vn');
  static final entryStore = stringMapStoreFactory.store('user_entry');

  static Future<AppDatabase> open() async {
    final db = await openAppDatabase(AppConstants.dbName);
    return AppDatabase._(db);
  }
}
