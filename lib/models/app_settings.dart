import 'package:flutter/material.dart';

/// Color themes offered in Settings → Appearance.
enum ThemePreset {
  vndex('Vndex'),
  dusk('Dusk'),
  catppuccin('Catppuccin');

  const ThemePreset(this.label);
  final String label;
}

/// How dates are shown (Settings → Appearance → Date format).
enum DateStyle {
  medium('Nov 8, 2026'),
  dayFirst('8 Nov 2026'),
  numeric('11/8/26'),
  iso('2026-11-08');

  const DateStyle(this.example);
  final String example;
}

/// How the home lists are ordered (sort button on the home screen).
enum ListSort {
  updated('Recently updated', Icons.update),
  title('Title A–Z', Icons.sort_by_alpha),
  score('Your score', Icons.star_outline),
  rating('VNDB rating', Icons.trending_up),
  added('Date added', Icons.playlist_add),
  released('Release date', Icons.event);

  const ListSort(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// All user settings. Immutable: change with [copyWith].
/// Defaults here are what a fresh install uses.
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.preset = ThemePreset.vndex,
    this.pureBlack = false,
    this.dateStyle = DateStyle.medium,
    this.blurSensitiveCovers = true,
    this.showSexualTags = false,
    this.listSort = ListSort.updated,
  });

  final ThemeMode themeMode;
  final ThemePreset preset;
  final bool pureBlack; // dark mode with true black background (OLED)
  final DateStyle dateStyle;

  // 18+ content
  final bool blurSensitiveCovers;
  final bool showSexualTags;

  /// Same sort for all four lists; remembered between launches.
  final ListSort listSort;

  AppSettings copyWith({
    ThemeMode? themeMode,
    ThemePreset? preset,
    bool? pureBlack,
    DateStyle? dateStyle,
    bool? blurSensitiveCovers,
    bool? showSexualTags,
    ListSort? listSort,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        preset: preset ?? this.preset,
        pureBlack: pureBlack ?? this.pureBlack,
        dateStyle: dateStyle ?? this.dateStyle,
        blurSensitiveCovers: blurSensitiveCovers ?? this.blurSensitiveCovers,
        showSexualTags: showSexualTags ?? this.showSexualTags,
        listSort: listSort ?? this.listSort,
      );

  Map<String, Object?> toJson() => {
        'themeMode': themeMode.name,
        'preset': preset.name,
        'pureBlack': pureBlack,
        'dateStyle': dateStyle.name,
        'blurSensitiveCovers': blurSensitiveCovers,
        'showSexualTags': showSexualTags,
        'listSort': listSort.name,
      };

  /// Unknown or missing values fall back to defaults, so adding a setting
  /// later never breaks old saved data.
  factory AppSettings.fromJson(Map<String, Object?> j) {
    T pick<T extends Enum>(List<T> values, Object? name, T fallback) =>
        values.firstWhere((v) => v.name == name, orElse: () => fallback);
    const d = AppSettings();

    return AppSettings(
      themeMode: pick(ThemeMode.values, j['themeMode'], d.themeMode),
      preset: pick(ThemePreset.values, j['preset'], d.preset),
      pureBlack: j['pureBlack'] as bool? ?? d.pureBlack,
      dateStyle: pick(DateStyle.values, j['dateStyle'], d.dateStyle),
      blurSensitiveCovers:
          j['blurSensitiveCovers'] as bool? ?? d.blurSensitiveCovers,
      showSexualTags: j['showSexualTags'] as bool? ?? d.showSexualTags,
      listSort: pick(ListSort.values, j['listSort'], d.listSort),
    );
  }
}
