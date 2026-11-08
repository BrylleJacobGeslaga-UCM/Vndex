// Opens the database the right way for each platform.
// Android/iOS: a file in the app's documents folder.
// Web: the browser's built-in storage (IndexedDB).
// Conditional export so web-only code never compiles for Android and vice versa.
export 'db_factory_io.dart'
    if (dart.library.js_interop) 'db_factory_web.dart';
