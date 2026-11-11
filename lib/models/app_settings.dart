import 'package:flutter/material.dart';

import 'library_prefs.dart';

export 'library_prefs.dart';

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
    this.library = const LibraryPrefs(),
    this.lastBackupAt,
  });

  final ThemeMode themeMode;
  final ThemePreset preset;
  final bool pureBlack; // dark mode with true black background (OLED)
  final DateStyle dateStyle;

  // 18+ content
  final bool blurSensitiveCovers;
  final bool showSexualTags;

  /// Home screen Filter · Sort · Display options.
  final LibraryPrefs library;

  /// When you last made a backup (shown in Data and storage).
  final DateTime? lastBackupAt;

  AppSettings copyWith({
    ThemeMode? themeMode,
    ThemePreset? preset,
    bool? pureBlack,
    DateStyle? dateStyle,
    bool? blurSensitiveCovers,
    bool? showSexualTags,
    LibraryPrefs? library,
    DateTime? lastBackupAt,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        preset: preset ?? this.preset,
        pureBlack: pureBlack ?? this.pureBlack,
        dateStyle: dateStyle ?? this.dateStyle,
        blurSensitiveCovers: blurSensitiveCovers ?? this.blurSensitiveCovers,
        showSexualTags: showSexualTags ?? this.showSexualTags,
        library: library ?? this.library,
        lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      );

  Map<String, Object?> toJson() => {
        'themeMode': themeMode.name,
        'preset': preset.name,
        'pureBlack': pureBlack,
        'dateStyle': dateStyle.name,
        'blurSensitiveCovers': blurSensitiveCovers,
        'showSexualTags': showSexualTags,
        'library': library.toJson(),
        'lastBackupAt': lastBackupAt?.millisecondsSinceEpoch,
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
      library: j['library'] is Map
          ? LibraryPrefs.fromJson((j['library'] as Map).cast<String, Object?>())
          // Older saves only had the sort; keep it.
          : LibraryPrefs(sort: pick(ListSort.values, j['listSort'], ListSort.updated)),
      lastBackupAt: j['lastBackupAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(j['lastBackupAt'] as int)
          : null,
    );
  }
}
