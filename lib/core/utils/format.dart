/// Small display helpers.
library;

import '../../models/app_settings.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Formats a date in the style chosen in Settings → Appearance.
String formatDate(DateTime d, [DateStyle style = DateStyle.medium]) {
  String two(int n) => n.toString().padLeft(2, '0');
  switch (style) {
    case DateStyle.medium:
      return '${_months[d.month - 1]} ${d.day}, ${d.year}';
    case DateStyle.dayFirst:
      return '${d.day} ${_months[d.month - 1]} ${d.year}';
    case DateStyle.numeric:
      return '${d.month}/${d.day}/${two(d.year % 100)}';
    case DateStyle.iso:
      return '${d.year}-${two(d.month)}-${two(d.day)}';
  }
}

/// 1500 → "~25 h", 45 → "~45 min"
String formatLength(int minutes) =>
    minutes < 60 ? '~$minutes min' : '~${(minutes / 60).round()} h';

/// VNDB descriptions use BBCode-style markup like [url=...]text[/url] and
/// [spoiler]...[/spoiler]. This turns it into plain text and removes spoilers.
String cleanVndbText(String raw) {
  var s = raw;
  // [url=https://...]Link text[/url] -> Link text
  s = s.replaceAllMapped(
    RegExp(r'\[url=[^\]]*\](.*?)\[/url\]', dotAll: true, caseSensitive: false),
    (m) => m[1] ?? '',
  );
  // Remove spoiler blocks entirely.
  s = s.replaceAll(
    RegExp(r'\[spoiler\].*?\[/spoiler\]', dotAll: true, caseSensitive: false),
    '',
  );
  // Strip any remaining tags like [b], [/i], [quote], [raw].
  s = s.replaceAll(RegExp(r'\[/?[a-z]+(=[^\]]*)?\]', caseSensitive: false), '');
  // Collapse 3+ blank lines left behind.
  s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return s.trim();
}
