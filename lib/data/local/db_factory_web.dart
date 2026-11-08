import 'package:sembast/sembast.dart';
import 'package:sembast_web/sembast_web.dart';

/// Web: store the database in the browser (IndexedDB).
/// Data is per browser — clearing site data in Chrome wipes it.
Future<Database> openAppDatabase(String name) =>
    databaseFactoryWeb.openDatabase(name);
