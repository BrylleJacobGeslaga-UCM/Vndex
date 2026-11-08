import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/app_settings.dart';
import '../../providers/providers.dart';
import 'widgets/settings_widgets.dart';

/// Theme mode, color theme, pure black, date format.
class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const SectionHeader('Theme'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('System')),
                ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
              ],
              selected: {s.themeMode},
              onSelectionChanged: (v) =>
                  notifier.update((c) => c.copyWith(themeMode: v.first)),
            ),
          ),
          const SizedBox(height: 20),

          // Theme preview cards
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: ThemePreset.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final preset = ThemePreset.values[i];
                return _ThemePreview(
                  preset: preset,
                  brightness: brightness,
                  pureBlack: s.pureBlack,
                  selected: s.preset == preset,
                  onTap: () => notifier.update((c) => c.copyWith(preset: preset)),
                );
              },
            ),
          ),

          SwitchListTile(
            title: const Text('Pure black dark mode'),
            subtitle: const Text('Saves battery on AMOLED screens'),
            value: s.pureBlack,
            onChanged: (v) => notifier.update((c) => c.copyWith(pureBlack: v)),
          ),

          const SectionHeader('Display'),
          ListTile(
            title: const Text('Date format'),
            subtitle: Text(s.dateStyle.example),
            onTap: () async {
              final picked = await showDialog<DateStyle>(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: const Text('Date format'),
                  children: [
                    for (final d in DateStyle.values)
                      ListTile(
                        title: Text(d.example),
                        trailing: d == s.dateStyle ? const Icon(Icons.check) : null,
                        onTap: () => Navigator.pop(ctx, d),
                      ),
                  ],
                ),
              );
              if (picked != null) {
                notifier.update((c) => c.copyWith(dateStyle: picked));
              }
            },
          ),
        ],
      ),
    );
  }
}

/// A tiny phone drawn in a theme's colors, like the cards in your screenshot.
class _ThemePreview extends StatelessWidget {
  const _ThemePreview({
    required this.preset,
    required this.brightness,
    required this.pureBlack,
    required this.selected,
    required this.onTap,
  });

  final ThemePreset preset;
  final Brightness brightness;
  final bool pureBlack;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.build(preset, brightness, pureBlack: pureBlack).colorScheme;
    final accent = Theme.of(context).colorScheme.primary;

    Widget pill(double w, double h, Color color) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(h)),
        );

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 104,
            height: 172,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? accent : c.outlineVariant,
                width: selected ? 3 : 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
                  child: pill(48, 14, c.onSurface.withValues(alpha: 0.85)),
                ),
                // A "card" with two accent dots
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 42,
                  height: 58,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: c.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.topLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      pill(9, 9, c.tertiary),
                      pill(9, 9, c.primary),
                    ],
                  ),
                ),
                const Spacer(),
                // Bottom bar
                Container(
                  color: c.surfaceContainer,
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Row(
                    children: [
                      pill(14, 14, c.primary),
                      const SizedBox(width: 6),
                      Expanded(child: pill(double.infinity, 10, c.outline)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            preset.label,
            style: TextStyle(
              color: selected ? accent : null,
              fontWeight: selected ? FontWeight.w600 : null,
            ),
          ),
        ],
      ),
    );
  }
}
