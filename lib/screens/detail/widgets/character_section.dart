import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/format.dart';
import '../../../core/widgets/sensitive_image.dart';
import '../../../models/character.dart';
import '../../../providers/providers.dart';

/// Characters as a horizontal row of cards. Shows protagonists and main
/// characters first; "Show all" adds side characters. Spoiler characters
/// are never included.
class CharacterSection extends ConsumerStatefulWidget {
  const CharacterSection({super.key, required this.vnId});

  final String vnId;

  @override
  ConsumerState<CharacterSection> createState() => _CharacterSectionState();
}

class _CharacterSectionState extends ConsumerState<CharacterSection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.outline;
    final async = ref.watch(vnCharactersProvider(widget.vnId));

    return async.when(
      loading: () => const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Row(
        children: [
          Expanded(
            child: Text('Could not load characters.', style: TextStyle(color: muted)),
          ),
          TextButton(
            onPressed: () => ref.invalidate(vnCharactersProvider(widget.vnId)),
            child: const Text('Retry'),
          ),
        ],
      ),
      data: (all) {
        if (all.isEmpty) return const SizedBox.shrink();

        final important = [
          for (final c in all)
            if (c.role.index <= CharacterRole.primary.index) c,
        ];
        // If a VN has no main characters listed, just show everyone.
        final shown = _showAll || important.isEmpty ? all : important;
        final hiddenCount = all.length - shown.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Characters (${all.length})', style: text.titleMedium),
                const Spacer(),
                if (hiddenCount > 0 || _showAll && important.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _showAll = !_showAll),
                    child: Text(_showAll ? 'Main only' : 'Show all'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 196,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: shown.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _CharacterCard(character: shown[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({required this.character});

  final VnCharacter character;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final c = character;

    return SizedBox(
      width: 100,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showCharacterSheet(context, c),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 100,
                height: 132,
                child: c.imageUrl == null
                    ? Container(
                        color: scheme.surfaceContainerHighest,
                        child: Icon(Icons.person_outline, size: 40, color: scheme.outline),
                      )
                    : SensitiveImage(
                        url: c.imageUrl!,
                        sensitive: c.isImageSensitive,
                        onTap: () => _showCharacterSheet(context, c),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(c.name, style: text.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
            Text(
              c.role.label,
              style: text.labelSmall?.copyWith(color: scheme.outline),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet with a bigger picture and the (spoiler-free) description.
void _showCharacterSheet(BuildContext context, VnCharacter c) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) {
      final text = Theme.of(ctx).textTheme;
      final scheme = Theme.of(ctx).colorScheme;
      final desc = c.description == null ? '' : cleanVndbText(c.description!);

      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (c.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 120,
                      height: 160,
                      child: SensitiveImage(url: c.imageUrl!, sensitive: c.isImageSensitive),
                    ),
                  ),
                if (c.imageUrl != null) const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name, style: text.titleLarge),
                      if (c.original != null && c.original != c.name)
                        Text(c.original!, style: text.bodyMedium?.copyWith(color: scheme.outline)),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(c.role.label),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              desc.isEmpty ? 'No description on VNDB.' : desc,
              style: desc.isEmpty
                  ? TextStyle(color: scheme.outline)
                  : text.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
        ),
      );
    },
  );
}
