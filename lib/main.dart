import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'data/local/app_database.dart';
import 'data/local/settings_store.dart';
import 'providers/providers.dart';
import 'screens/home/home_screen.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // Keep the splash screen up while the database and settings load,
  // so the app opens straight into your lists with the right theme.
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  final db = await AppDatabase.open();
  final settings = await SettingsStore(db).load();

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        initialSettingsProvider.overrideWithValue(settings),
      ],
      child: const VndexApp(),
    ),
  );

  FlutterNativeSplash.remove();
}

class VndexApp extends ConsumerWidget {
  const VndexApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Vndex',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(s.preset, Brightness.light),
      darkTheme: AppTheme.build(s.preset, Brightness.dark, pureBlack: s.pureBlack),
      themeMode: s.themeMode,
      home: const HomeScreen(),
    );
  }
}
