import 'package:sembast/sembast.dart';

import '../../models/app_settings.dart';
import 'app_database.dart';

/// Loads and saves [AppSettings] as one record in the local database.
class SettingsStore {
  SettingsStore(this._db);

  final AppDatabase _db;
  final _record = AppDatabase.settingsStore.record('app');

  Future<AppSettings> load() async {
    final json = await _record.get(_db.db);
    return json == null ? const AppSettings() : AppSettings.fromJson(json);
  }

  Future<void> save(AppSettings settings) =>
      _record.put(_db.db, settings.toJson());
}
