import 'package:flutter/material.dart';

/// How the home lists are ordered.
enum ListSort {
  updated('Recently updated', true),
  title('Title', false),
  score('Your score', true),
  rating('VNDB rating', true),
  added('Date added', true),
  released('Release date', true);

  const ListSort(this.label, this.naturallyDescending);
  final String label;

  /// Default direction: newest/highest first, except title (A–Z).
  final bool naturallyDescending;
}

/// How the home lists look (Display tab).
enum LibraryDisplay {
  compactGrid('Compact grid'),
  comfortableGrid('Comfortable grid'),
  coverOnlyGrid('Cover-only grid'),
  list('List');

  const LibraryDisplay(this.label);
  final String label;

  bool get isGrid => this != LibraryDisplay.list;
}

/// A filter checkbox with three states: off → only these → exclude these.
enum TriState {
  any,
  only,
  exclude;

  TriState get next => TriState.values[(index + 1) % TriState.values.length];

  /// Does a VN with/without the property pass this filter?
  bool allows(bool has) => switch (this) {
        TriState.any => true,
        TriState.only => has,
        TriState.exclude => !has,
      };

  IconData get icon => switch (this) {
        TriState.any => Icons.check_box_outline_blank,
        TriState.only => Icons.check_box,
        TriState.exclude => Icons.disabled_by_default,
      };
}

/// Everything set in the library sheet (Filter · Sort · Display).
/// Stored inside AppSettings so it's remembered between launches.
class LibraryPrefs {
  const LibraryPrefs({
    this.sort = ListSort.updated,
    this.sortReversed = false,
    this.display = LibraryDisplay.list,
    this.gridColumns = 3,
    this.showScore = true,
    this.showStatus = true,
    this.showRating = true,
    this.showNote = true,
    this.showTabs = true,
    this.showTabCounts = true,
    this.filterScored = TriState.any,
    this.filterHasNote = TriState.any,
    this.filterReleased = TriState.any,
  });

  // Sort
  final ListSort sort;
  final bool sortReversed; // flips the natural direction

  // Display
  final LibraryDisplay display;
  final int gridColumns; // 2–6
  final bool showScore; // ★ score badge
  final bool showStatus; // list badge in the "All" tab
  final bool showRating; // VNDB rating (list view)
  final bool showNote; // progress note line (list view)
  final bool showTabs; // off = only "All", no tab bar
  final bool showTabCounts;

  // Filter
  final TriState filterScored;
  final TriState filterHasNote;
  final TriState filterReleased;

  static const minColumns = 2;
  static const maxColumns = 6;

  /// Actual direction after flipping.
  bool get descending => sort.naturallyDescending != sortReversed;

  /// Lights up the filter icon when any filter is on.
  bool get hasActiveFilter =>
      filterScored != TriState.any ||
      filterHasNote != TriState.any ||
      filterReleased != TriState.any;

  LibraryPrefs copyWith({
    ListSort? sort,
    bool? sortReversed,
    LibraryDisplay? display,
    int? gridColumns,
    bool? showScore,
    bool? showStatus,
    bool? showRating,
    bool? showNote,
    bool? showTabs,
    bool? showTabCounts,
    TriState? filterScored,
    TriState? filterHasNote,
    TriState? filterReleased,
  }) =>
      LibraryPrefs(
        sort: sort ?? this.sort,
        sortReversed: sortReversed ?? this.sortReversed,
        display: display ?? this.display,
        gridColumns: gridColumns ?? this.gridColumns,
        showScore: showScore ?? this.showScore,
        showStatus: showStatus ?? this.showStatus,
        showRating: showRating ?? this.showRating,
        showNote: showNote ?? this.showNote,
        showTabs: showTabs ?? this.showTabs,
        showTabCounts: showTabCounts ?? this.showTabCounts,
        filterScored: filterScored ?? this.filterScored,
        filterHasNote: filterHasNote ?? this.filterHasNote,
        filterReleased: filterReleased ?? this.filterReleased,
      );

  Map<String, Object?> toJson() => {
        'sort': sort.name,
        'sortReversed': sortReversed,
        'display': display.name,
        'gridColumns': gridColumns,
        'showScore': showScore,
        'showStatus': showStatus,
        'showRating': showRating,
        'showNote': showNote,
        'showTabs': showTabs,
        'showTabCounts': showTabCounts,
        'filterScored': filterScored.name,
        'filterHasNote': filterHasNote.name,
        'filterReleased': filterReleased.name,
      };

  /// Missing/unknown values fall back to defaults.
  factory LibraryPrefs.fromJson(Map<String, Object?> j) {
    T pick<T extends Enum>(List<T> values, Object? name, T fallback) =>
        values.firstWhere((v) => v.name == name, orElse: () => fallback);
    const d = LibraryPrefs();

    return LibraryPrefs(
      sort: pick(ListSort.values, j['sort'], d.sort),
      sortReversed: j['sortReversed'] as bool? ?? d.sortReversed,
      display: pick(LibraryDisplay.values, j['display'], d.display),
      gridColumns: ((j['gridColumns'] as int?) ?? d.gridColumns)
          .clamp(minColumns, maxColumns),
      showScore: j['showScore'] as bool? ?? d.showScore,
      showStatus: j['showStatus'] as bool? ?? d.showStatus,
      showRating: j['showRating'] as bool? ?? d.showRating,
      showNote: j['showNote'] as bool? ?? d.showNote,
      showTabs: j['showTabs'] as bool? ?? d.showTabs,
      showTabCounts: j['showTabCounts'] as bool? ?? d.showTabCounts,
      filterScored: pick(TriState.values, j['filterScored'], d.filterScored),
      filterHasNote: pick(TriState.values, j['filterHasNote'], d.filterHasNote),
      filterReleased: pick(TriState.values, j['filterReleased'], d.filterReleased),
    );
  }
}
