/// Small display helpers.

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "Nov 8, 2026"
String formatDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

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
