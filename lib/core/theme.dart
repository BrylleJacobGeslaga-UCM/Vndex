import 'package:flutter/material.dart';

import '../models/app_settings.dart';

/// Builds the app's look from Settings → Appearance.
class AppTheme {
  AppTheme._();

  /// Full theme for one preset in light or dark.
  static ThemeData build(
    ThemePreset preset,
    Brightness brightness, {
    bool pureBlack = false,
  }) {
    var scheme = schemeFor(preset, brightness);
    if (brightness == Brightness.dark && pureBlack) scheme = _pureBlack(scheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      // Settings-style section headers and list icons pick up the accent.
      listTileTheme: ListTileThemeData(iconColor: scheme.primary),
    );
  }

  /// Just the colors (also used to draw the preview cards).
  static ColorScheme schemeFor(ThemePreset preset, Brightness b) {
    final dark = b == Brightness.dark;
    switch (preset) {
      case ThemePreset.vndex:
        return ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C5CE7),
          brightness: b,
        );

      // Navy background with a warm orange accent.
      case ThemePreset.dusk:
        final base = ColorScheme.fromSeed(
          seedColor: const Color(0xFFF4B272),
          brightness: b,
        );
        if (!dark) return base;
        return base.copyWith(
          primary: const Color(0xFFF4B272),
          onPrimary: const Color(0xFF3A2410),
          primaryContainer: const Color(0xFF5E4C46),
          onPrimaryContainer: const Color(0xFFFFDCC0),
          secondaryContainer: const Color(0xFF5E4C46),
          onSecondaryContainer: const Color(0xFFF4B272),
          surface: const Color(0xFF1F202B),
          onSurface: const Color(0xFFE4E1EC),
          onSurfaceVariant: const Color(0xFFC6C3D0),
          surfaceContainerLowest: const Color(0xFF191A23),
          surfaceContainerLow: const Color(0xFF252632),
          surfaceContainer: const Color(0xFF2A2B38),
          surfaceContainerHigh: const Color(0xFF30313F),
          surfaceContainerHighest: const Color(0xFF393A49),
          outline: const Color(0xFF8E8C99),
          outlineVariant: const Color(0xFF45465A),
        );

      // Catppuccin: Mocha in dark, Latte in light.
      case ThemePreset.catppuccin:
        return dark
            ? ColorScheme.fromSeed(
                seedColor: const Color(0xFFCBA6F7),
                brightness: b,
              ).copyWith(
                primary: const Color(0xFFCBA6F7), // mauve
                onPrimary: const Color(0xFF1E1E2E),
                secondary: const Color(0xFFB4BEFE), // lavender
                tertiary: const Color(0xFFA6E3A1), // green
                secondaryContainer: const Color(0xFF45475A),
                onSecondaryContainer: const Color(0xFFCDD6F4),
                surface: const Color(0xFF1E1E2E), // base
                onSurface: const Color(0xFFCDD6F4), // text
                onSurfaceVariant: const Color(0xFFBAC2DE),
                surfaceContainerLowest: const Color(0xFF11111B), // crust
                surfaceContainerLow: const Color(0xFF181825), // mantle
                surfaceContainer: const Color(0xFF26263A),
                surfaceContainerHigh: const Color(0xFF313244), // surface0
                surfaceContainerHighest: const Color(0xFF45475A), // surface1
                outline: const Color(0xFF7F849C),
                outlineVariant: const Color(0xFF45475A),
                error: const Color(0xFFF38BA8),
              )
            : ColorScheme.fromSeed(
                seedColor: const Color(0xFF8839EF),
                brightness: b,
              ).copyWith(
                primary: const Color(0xFF8839EF),
                secondary: const Color(0xFF7287FD),
                tertiary: const Color(0xFF40A02B),
                surface: const Color(0xFFEFF1F5), // base
                onSurface: const Color(0xFF4C4F69), // text
                surfaceContainerLowest: const Color(0xFFFFFFFF),
                surfaceContainerLow: const Color(0xFFE6E9EF), // mantle
                surfaceContainer: const Color(0xFFE1E4EB),
                surfaceContainerHigh: const Color(0xFFDCE0E8), // crust
                surfaceContainerHighest: const Color(0xFFCCD0DA), // surface0
                error: const Color(0xFFD20F39),
              );
    }
  }

  /// OLED-friendly: black background, near-black cards.
  static ColorScheme _pureBlack(ColorScheme s) => s.copyWith(
        surface: Colors.black,
        surfaceContainerLowest: Colors.black,
        surfaceContainerLow: const Color(0xFF0B0B0D),
        surfaceContainer: const Color(0xFF121214),
        surfaceContainerHigh: const Color(0xFF1A1A1D),
        surfaceContainerHighest: const Color(0xFF232327),
      );
}
