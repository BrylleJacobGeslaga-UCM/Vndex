import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/format.dart';
import '../../core/widgets/add_to_list_sheet.dart';
import '../../core/widgets/collection_picker_sheet.dart';
import '../../core/widgets/vn_cover.dart';
import '../../models/browse_filter.dart';
import '../../models/english.dart';
import '../../models/vn.dart';
import '../../providers/providers.dart';
import '../browse/browse_screen.dart';
import 'widgets/character_section.dart';
import 'widgets/description_section.dart';
import 'widgets/quote_section.dart';
import 'widgets/rating_review_card.dart';
import 'widgets/related_section.dart';
import 'widgets/screenshot_section.dart';
import 'widgets/staff_section.dart';
import 'widgets/tag_section.dart';
import 'widgets/vndb_links_card.dart';

/// Everything about one VN: header (with tappable studios), your rating &
/// review, description, related VNs, screenshots, characters, tags,
/// quotes, and links to the VNDB discussion board.
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
              : Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        icon: Icon(entry.status.icon),
                        label: Text(entry.status.label),
                        onPressed: () => showAddToListSheet(context, shown),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CollectionsButton(vn: shown),
                  ],
                ),

          if (entry != null) ...[
            const SizedBox(height: 16),
            RatingReviewCard(key: ValueKey(entry.vnId), vn: shown, entry: entry),
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
                if (d.relations.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  RelatedSection(relations: d.relations),
                ],
                if (d.staff.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  StaffSection(staff: d.staff),
                ],
                if (d.screenshots.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  ScreenshotSection(screenshots: d.screenshots),
                ],
                const SizedBox(height: 24),
                CharacterSection(vnId: d.id),
                const SizedBox(height: 24),
                TagSection(vn: d),
                const SizedBox(height: 24),
                QuoteSection(vnId: d.id),
                const SizedBox(height: 16),
                VndbLinksCard(vnId: d.id),
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
              if (vn.developerList.isNotEmpty) _DeveloperLinks(vn: vn),
              _EnglishLine(vnId: vn.id),
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

/// Developer names as links. Tap one to browse that studio's VNs.
class _DeveloperLinks extends StatelessWidget {
  const _DeveloperLinks({required this.vn});

  final Vn vn;

  void _open(BuildContext context, VnDeveloper dev) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BrowseScreen(
        title: 'By ${dev.name}',
        initialFilter: BrowseFilter(developer: dev),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.business, size: 16, color: scheme.outline),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Wrap(
              spacing: 4,
              runSpacing: 2,
              children: [
                for (var i = 0; i < vn.developerList.length; i++)
                  _link(context, vn.developerList[i],
                      last: i == vn.developerList.length - 1, style: style),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _link(BuildContext context, VnDeveloper dev,
      {required bool last, TextStyle? style}) {
    final scheme = Theme.of(context).colorScheme;
    final label = last ? dev.name : '${dev.name},';

    // Old saved VNs may not have the studio id yet; show plain text until
    // the page refreshes from VNDB.
    if (dev.id == null) return Text(label, style: style);

    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () => _open(context, dev),
      child: Text(
        label,
        style: style?.copyWith(
          color: scheme.primary,
          decoration: TextDecoration.underline,
          decorationColor: scheme.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

/// Opens the collection picker; shows how many collections the VN is in.
class _CollectionsButton extends ConsumerWidget {
  const _CollectionsButton({required this.vn});

  final Vn vn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(vnCollectionsProvider(vn.id)).maybeWhen(
          data: (k) => k.length,
          orElse: () => 0,
        );
    return OutlinedButton.icon(
      icon: Icon(count > 0 ? Icons.folder : Icons.create_new_folder_outlined),
      label: Text(count > 0 ? '$count' : 'Collect'),
      onPressed: () => showCollectionPicker(context, vn),
    );
  }
}

/// "Official English release" / "Fan translation" / … under the studio.
class _EnglishLine extends ConsumerWidget {
  const _EnglishLine({required this.vnId});

  final String vnId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final english = ref.watch(englishProvider(vnId)).maybeWhen(
          data: (e) => e,
          orElse: () => null,
        );
    if (english == null) return const SizedBox.shrink(); // loading/offline

    final scheme = Theme.of(context).colorScheme;
    final color = switch (english.kind) {
      EnglishKind.official => const Color(0xFF4CAF6A),
      EnglishKind.upcoming => const Color(0xFFE0A33A),
      EnglishKind.fan => const Color(0xFF4F8EF7),
      EnglishKind.machine || EnglishKind.none => scheme.outline,
    };

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(english.kind.icon, size: 16, color: color),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              english.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: english.kind.isPlayable ? FontWeight.w600 : null,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
