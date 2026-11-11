// Keeps the Android home screen widget up to date.
// Android gets the real thing; on web there's no widget, so it does nothing.
export 'home_widget_sync_io.dart'
    if (dart.library.js_interop) 'home_widget_sync_web.dart';
