import 'package:flutter/material.dart';

import '../../../core/widgets/vn_cover.dart';
import '../../../models/vn.dart';

/// One row in the search results.
class VnResultTile extends StatelessWidget {
  const VnResultTile({super.key, required this.vn, this.onTap});

  final Vn vn;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.outline;

    final meta = [
      if (vn.releaseYear != null) vn.releaseYear!,
      if (vn.developers.isNotEmpty) vn.developers.first,
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VnCover(vn: vn),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vn.title,
                    style: text.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (vn.altTitle != null && vn.altTitle != vn.title)
                    Text(
                      vn.altTitle!,
                      style: text.bodySmall?.copyWith(color: muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  if (meta.isNotEmpty)
                    Text(meta, style: text.bodySmall?.copyWith(color: muted)),
                  if (vn.ratingLabel != null)
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(vn.ratingLabel!, style: text.bodySmall),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
