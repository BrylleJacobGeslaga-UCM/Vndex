import 'vn.dart';

/// A tag picked in the filter sheet (id + name is all VNDB needs).
class TagRef {
  const TagRef({required this.id, required this.name, this.category = 'cont'});

  final String id; // "g7"
  final String name;
  final String category; // "cont", "tech", "ero"

  bool get isSexual => category == 'ero';

  /// From a tag on a VN page. Caller makes sure [t.id] isn't null.
  factory TagRef.fromVnTag(VnTag t) =>
      TagRef(id: t.id!, name: t.name, category: t.category);

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'category': category};

  factory TagRef.fromJson(Map<String, Object?> j) => TagRef(
        id: j['id'] as String,
        name: j['name'] as String,
        category: j['category'] as String? ?? 'cont',
      );

  @override
  bool operator ==(Object other) => other is TagRef && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// How Browse results are ordered.
enum BrowseSort {
  popular('votecount', 'Most popular', true),
  rating('rating', 'Top rated', true),
  newest('released', 'Newest release', true),
  title('title', 'Title A–Z', false);

  const BrowseSort(this.apiValue, this.label, this.reverse);
  final String apiValue;
  final String label;
  final bool reverse; // true = highest first
}

/// Option lists for the filter sheet. Keys are VNDB's own codes.
class FilterOptions {
  FilterOptions._();

  static const languages = {
    'ja': 'Japanese',
    'en': 'English',
    'zh-Hans': 'Chinese (Simplified)',
    'zh-Hant': 'Chinese (Traditional)',
    'ko': 'Korean',
  };

  static const platforms = {
    'win': 'Windows',
    'and': 'Android',
    'ios': 'iOS',
    'swi': 'Switch',
    'ps4': 'PS4',
    'ps5': 'PS5',
    'psv': 'PS Vita',
    'mac': 'macOS',
    'lin': 'Linux',
    'web': 'Browser',
  };

  static const lengths = {
    1: 'Very short (< 2 h)',
    2: 'Short (2–10 h)',
    3: 'Medium (10–30 h)',
    4: 'Long (30–50 h)',
    5: 'Very long (> 50 h)',
  };

  static const devStatus = {
    0: 'Finished',
    1: 'In development',
    2: 'Cancelled',
  };
}

/// Everything the filter sheet can set. Immutable: use [copyWith].
class BrowseFilter {
  const BrowseFilter({
    this.sort = BrowseSort.popular,
    this.languages = const {},
    this.platforms = const {},
    this.lengths = const {},
    this.devStatus = const {},
    this.minRating,
    this.yearFrom,
    this.yearTo,
    this.releasedOnly = false,
    this.includeTags = const [],
    this.excludeTags = const [],
    this.excludeVnId,
    this.developer,
    this.staff,
    this.englishOnly = false,
  });

  final BrowseSort sort;
  final Set<String> languages; // original language
  final Set<String> platforms;
  final Set<int> lengths;
  final Set<int> devStatus;
  final int? minRating; // 1–10
  final int? yearFrom;
  final int? yearTo;
  final bool releasedOnly; // hide upcoming/TBA (used by "Latest")
  final List<TagRef> includeTags; // must have ALL of these
  final List<TagRef> excludeTags; // must have NONE of these
  final String? excludeVnId; // "Find similar" hides the VN itself; not saved

  /// Only VNs by this developer (set by tapping a studio on a VN page).
  final VnDeveloper? developer;

  /// Only VNs this person worked on (set by tapping a staff name).
  final StaffRef? staff;

  /// Only VNs with an English release (official or fan translation).
  final bool englishOnly;

  /// The "Popular" chip.
  static const popular = BrowseFilter();

  /// The "Latest" chip: newest released VNs, no upcoming ones.
  static const latest = BrowseFilter(sort: BrowseSort.newest, releasedOnly: true);

  /// Number shown on the Filter chip.
  int get activeCount =>
      languages.length +
      platforms.length +
      lengths.length +
      devStatus.length +
      (minRating != null ? 1 : 0) +
      (yearFrom != null || yearTo != null ? 1 : 0) +
      includeTags.length +
      excludeTags.length +
      (developer != null ? 1 : 0) +
      (staff != null ? 1 : 0) +
      (englishOnly ? 1 : 0);

  BrowseFilter copyWith({
    BrowseSort? sort,
    Set<String>? languages,
    Set<String>? platforms,
    Set<int>? lengths,
    Set<int>? devStatus,
    int? Function()? minRating, // wrapped so it can be set to null
    int? Function()? yearFrom,
    int? Function()? yearTo,
    bool? releasedOnly,
    List<TagRef>? includeTags,
    List<TagRef>? excludeTags,
    VnDeveloper? Function()? developer, // wrapped so it can be set to null
    StaffRef? Function()? staff,
    bool? englishOnly,
  }) =>
      BrowseFilter(
        sort: sort ?? this.sort,
        languages: languages ?? this.languages,
        platforms: platforms ?? this.platforms,
        lengths: lengths ?? this.lengths,
        devStatus: devStatus ?? this.devStatus,
        minRating: minRating != null ? minRating() : this.minRating,
        yearFrom: yearFrom != null ? yearFrom() : this.yearFrom,
        yearTo: yearTo != null ? yearTo() : this.yearTo,
        releasedOnly: releasedOnly ?? this.releasedOnly,
        includeTags: includeTags ?? this.includeTags,
        excludeTags: excludeTags ?? this.excludeTags,
        excludeVnId: excludeVnId,
        developer: developer != null ? developer() : this.developer,
        staff: staff != null ? staff() : this.staff,
        englishOnly: englishOnly ?? this.englishOnly,
      );

  /// Turns the filter into VNDB's filter format.
  List<Object> toVndbFilters({String query = ''}) {
    // Several choices in one section = match ANY of them.
    Object anyOf(String field, Iterable<Object> values) => values.length == 1
        ? [field, '=', values.first]
        : ['or', for (final v in values) [field, '=', v]];

    final today = DateTime.now().toIso8601String().substring(0, 10);

    return [
      if (query.isNotEmpty) ['search', '=', query],
      if (languages.isNotEmpty) anyOf('olang', languages),
      if (platforms.isNotEmpty) anyOf('platform', platforms),
      if (lengths.isNotEmpty) anyOf('length', lengths),
      if (devStatus.isNotEmpty) anyOf('devstatus', devStatus),
      if (minRating != null) ['rating', '>=', minRating! * 10],
      if (yearFrom != null) ['released', '>=', '$yearFrom-01-01'],
      if (yearTo != null) ['released', '<=', '$yearTo-12-31'],
      if (releasedOnly) ['released', '<=', today],
      // [tag id, max spoiler level, min tag level]
      for (final t in includeTags) ['tag', '=', [t.id, 0, 1]],
      for (final t in excludeTags) ['tag', '!=', [t.id, 0, 1]],
      if (excludeVnId != null) ['id', '!=', excludeVnId!],
      if (developer?.id != null) ['developer', '=', ['id', '=', developer!.id!]],
      if (staff != null) ['staff', '=', ['id', '=', staff!.id]],
      if (englishOnly) ['lang', '=', 'en'],
    ];
  }

  // ---- Saving searches ----

  Map<String, Object?> toJson() => {
        'sort': sort.name,
        'languages': languages.toList(),
        'platforms': platforms.toList(),
        'lengths': lengths.toList(),
        'devStatus': devStatus.toList(),
        'minRating': minRating,
        'yearFrom': yearFrom,
        'yearTo': yearTo,
        'releasedOnly': releasedOnly,
        'includeTags': [for (final t in includeTags) t.toJson()],
        'excludeTags': [for (final t in excludeTags) t.toJson()],
        if (developer != null) 'developer': developer!.toJson(),
        if (staff != null) 'staff': staff!.toJson(),
        'englishOnly': englishOnly,
      };

  factory BrowseFilter.fromJson(Map<String, Object?> j) {
    List<T> list<T>(String key) => ((j[key] as List<Object?>?) ?? []).cast<T>();
    List<TagRef> tags(String key) => [
          for (final t in list<Map<String, Object?>>(key)) TagRef.fromJson(t),
        ];

    return BrowseFilter(
      sort: BrowseSort.values.firstWhere(
        (s) => s.name == j['sort'],
        orElse: () => BrowseSort.popular,
      ),
      languages: list<String>('languages').toSet(),
      platforms: list<String>('platforms').toSet(),
      lengths: list<int>('lengths').toSet(),
      devStatus: list<int>('devStatus').toSet(),
      minRating: j['minRating'] as int?,
      yearFrom: j['yearFrom'] as int?,
      yearTo: j['yearTo'] as int?,
      releasedOnly: j['releasedOnly'] as bool? ?? false,
      includeTags: tags('includeTags'),
      excludeTags: tags('excludeTags'),
      developer: j['developer'] == null ? null : VnDeveloper.fromStored(j['developer']),
      staff: j['staff'] is Map
          ? StaffRef.fromJson((j['staff'] as Map).cast<String, Object?>())
          : null,
      englishOnly: j['englishOnly'] as bool? ?? false,
    );
  }
}

/// A named filter saved from the filter sheet.
class SavedSearch {
  const SavedSearch({required this.key, required this.name, required this.filter});

  final int key;
  final String name;
  final BrowseFilter filter;
}
