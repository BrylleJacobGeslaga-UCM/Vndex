import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/format.dart';
import '../../core/widgets/add_to_list_sheet.dart';
import '../../core/widgets/vn_cover.dart';
import '../../models/vn.dart';
import '../../providers/providers.dart';
import 'widgets/character_section.dart';
import 'widgets/description_section.dart';
import 'widgets/progress_card.dart';
import 'widgets/screenshot_section.dart';
import 'widgets/tag_section.dart';

/// Everything about one VN: header, your progress, description,
/// screenshots, characters, tags.
///
/// Opens instantly using the [vn] you tapped (title, cover, etc.), then
/// loads the description and tags from VNDB underneath.
class DetailScreen extends ConsumerWidget {
  const DetailScreen({super.key, required this.vn});

  final Vn vn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(vnDetailsProvider(vn.id));
    final entry = ref.watch(userEntryProvider(vn.id)).maybeWhen(
          data: (e) => e,
          orElse: () => null,
        );

    // Use the fuller version once it arrives, the tapped one until then.
    final shown = details.maybeWhen(data: (d) => d, orElse: () => vn);

    return Scaffold(
      appBar: AppBar(title: Text(shown.title, overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _Header(vn: shown),
          const SizedBox(height: 16),

          // Add / change list.
          entry == null
              ? FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add to list'),
                  onPressed: () => showAddToListSheet(context, shown),
                )
              : FilledButton.tonalIcon(
                  icon: Icon(entry.status.icon),
                  label: Text(entry.status.label),
                  onPressed: () => showAddToListSheet(context, shown),
                ),

          if (entry != null) ...[
            const SizedBox(height: 16),
            ProgressCard(key: ValueKey(entry.vnId), entry: entry),
          ],

          const SizedBox(height: 24),
          details.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => _LoadError(
              message: '$e',
              onRetry: () => ref.invalidate(vnDetailsProvider(vn.id)),
            ),
            data: (d) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DescriptionSection(raw: d.description),
                if (d.screenshots.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  ScreenshotSection(screenshots: d.screenshots),
                ],
                const SizedBox(height: 24),
                CharacterSection(vnId: d.id),
                const SizedBox(height: 24),
                TagSection(vn: d),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.vn});

  final Vn vn;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.outline;

    Widget info(IconData icon, String value) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Icon(icon, size: 16, color: muted),
              const SizedBox(width: 6),
              Expanded(child: Text(value, style: text.bodyMedium)),
            ],
          ),
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VnCover(vn: vn, width: 120),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(vn.title, style: text.titleLarge),
              if (vn.altTitle != null && vn.altTitle != vn.title)
                Text(vn.altTitle!, style: text.bodyMedium?.copyWith(color: muted)),
              const SizedBox(height: 4),
              if (vn.released != null) info(Icons.event, vn.released!),
              if (vn.developers.isNotEmpty)
                info(Icons.business, vn.developers.join(', ')),
              if (vn.lengthMinutes != null)
                info(Icons.schedule, formatLength(vn.lengthMinutes!)),
              if (vn.ratingLabel != null)
                info(Icons.star_outline, '${vn.ratingLabel} on VNDB'),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Could not load details.\n$message',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.outline),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}
