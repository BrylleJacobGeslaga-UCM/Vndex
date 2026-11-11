import 'package:flutter/material.dart';

import '../../../core/widgets/list_badge.dart';
import '../../../core/widgets/vn_cover.dart';
import '../../../models/vn.dart';
import '../detail_screen.dart';

/// Prequels, sequels, fandiscs and other related VNs as a row of covers.
/// Tap one to open its page.
class RelatedSection extends StatelessWidget {
  const RelatedSection({super.key, required this.relations});

  final List<VnRelation> relations;

  @override
  Widget build(BuildContext context) {
    if (relations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Related (${relations.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 232,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: relations.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _RelatedCard(relation: relations[i]),
          ),
        ),
      ],
    );
  }
}

class _RelatedCard extends StatelessWidget {
  const _RelatedCard({required this.relation});

  final VnRelation relation;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final vn = relation.vn;

    void open() => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DetailScreen(vn: vn)),
        );

    return SizedBox(
      width: 100,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: open,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover, with your list badge on top if it's in one of your lists.
            Stack(
              children: [
                VnCover(vn: vn, width: 100),
                Positioned(
                  left: 4,
                  right: 4,
                  bottom: 4,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: ListBadge(vnId: vn.id),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Relation type: prequel/sequel highlighted in the accent color.
            Text(
              relation.official ? relation.label : '${relation.label} (unofficial)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelSmall?.copyWith(
                color: relation.isStoryOrder ? scheme.primary : scheme.outline,
                fontWeight: relation.isStoryOrder ? FontWeight.w700 : null,
              ),
            ),
            Text(
              vn.title,
              style: text.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (vn.releaseYear != null)
              Text(
                vn.releaseYear!,
                style: text.labelSmall?.copyWith(color: scheme.outline),
              ),
          ],
        ),
      ),
    );
  }
}
