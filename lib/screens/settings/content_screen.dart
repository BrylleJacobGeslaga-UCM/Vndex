import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import 'widgets/settings_widgets.dart';

/// 18+ content options.
class ContentScreen extends ConsumerWidget {
  const ContentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Content')),
      body: ListView(
        children: [
          const SectionHeader('Adult content (18+)'),
          SwitchListTile(
            title: const Text('Blur sensitive covers'),
            subtitle: const Text('Covers VNDB marks as suggestive or explicit'),
            value: s.blurSensitiveCovers,
            onChanged: (v) =>
                notifier.update((c) => c.copyWith(blurSensitiveCovers: v)),
          ),
          SwitchListTile(
            title: const Text('Show sexual content tags'),
            subtitle: const Text('On VN pages, without tapping "Show"'),
            value: s.showSexualTags,
            onChanged: (v) =>
                notifier.update((c) => c.copyWith(showSexualTags: v)),
          ),
          const InfoNote(
            'With blur on, you can still tap a blurred cover to reveal it. '
            'VNDB rates covers by community vote, so a few may be missed or '
            'blurred unnecessarily. In Chrome, sensitive covers are hidden '
            'instead of blurred.',
          ),
        ],
      ),
    );
  }
}
