// Saving and opening backup files works differently on Android and web,
// so each platform has its own file (same idea as db_factory.dart).
export 'backup_file_io.dart'
    if (dart.library.js_interop) 'backup_file_web.dart';
