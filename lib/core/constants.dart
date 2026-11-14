/// Shared constants. Keep URLs and magic numbers here, not inside widgets.
class AppConstants {
  AppConstants._();

  /// Shown in Settings → About. Keep in sync with `version:` in pubspec.yaml.
  static const String appVersion = '1.1.1';

  /// Live VNDB API (Kana).
  static const String vndbApiBase = 'https://api.vndb.org/kana';

  /// Sandbox for testing. Swap into [vndbApiBase] while experimenting.
  static const String vndbSandboxBase = 'https://beta.vndb.org/api/kana';

  /// Wait this long after the user stops typing before searching.
  static const Duration searchDebounce = Duration(milliseconds: 500);

  /// Local SQLite file name.
  static const String dbName = 'vndex.db';
}
