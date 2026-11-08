import 'package:flutter/material.dart';

/// App-wide colors and theme. Change [_seed] to re-color the whole app.
class AppTheme {
  AppTheme._();

  static const Color _seed = Color(0xFF6C5CE7); // soft purple

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seed),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
      );
}
