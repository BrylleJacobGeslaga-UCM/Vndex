import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/format.dart';
import '../../../core/widgets/star_rating.dart';
import '../../../models/user_entry.dart';
import '../../../models/vn.dart';
import '../../../providers/providers.dart';
import '../review_editor_screen.dart';

/// "Your rating & review": stars, your review, and the list dates.
/// Only shown for VNs in one of your lists.
class RatingReviewCard extends ConsumerStatefulWidget {
  const RatingReviewCard({super.key, required this.vn, required this.entry});

  final Vn vn;
  final UserEntry entry;

  @override
  ConsumerState<RatingReviewCard> createState() => _RatingReviewCardState();
}

class _RatingReviewCardState extends ConsumerState<RatingReviewCard> {
  /// Shown immediately while saving, so the stars follow your finger.
  int? _pending;
  bool _hasPending = false;

  bool _expanded = false;
  bool _spoilerRevealed = false;

  Future<void> _setScore(int? score) async {
    setState(() {
      _pending = score;
      _hasPending = true;
    });
    await ref.read(vnRepositoryProvider).setScore(widget.entry.vnId, score);
    ref.invalidate(userEntryProvider(widget.entry.vnId));
    if (mounted) setState(() => _hasPending = false);
  }

  Future<void> _editReview() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ReviewEditorScreen(vn: widget.vn, entry: widget.entry),
      ),
    );
    if (saved == true) ref.invalidate(userEntryProvider(widget.entry.vnId));
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final dateStyle = ref.watch(settingsProvider.select((s) => s.dateStyle));
    final score = _hasPending ? _pending : entry.score;
    final review = entry.review;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Rating ----
            Row(
              children: [
                Text('Your rating', style: text.titleMedium),
                const Spacer(),
                Text(
                  score == null ? 'Not rated' : '${formatStars(score)} / 5',
                  style: text.titleSmall?.copyWith(
                    color: score == null ? scheme.outline : scheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(child: StarRating(value: score, onChanged: _setScore, size: 44)),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Tap or slide for half stars · tap again to clear',
                style: text.labelSmall?.copyWith(color: scheme.outline),
              ),
            ),

            const Divider(height: 32),

            // ---- Review ----
            Row(
              children: [
                Text('Your review', style: text.titleMedium),
                const Spacer(),
                if (review != null)
                  TextButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                    onPressed: _editReview,
                  ),
              ],
            ),
            if (review == null)
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Text('Write a review'),
                  onPressed: _editReview,
                ),
              )
            else if (entry.reviewSpoiler && !_spoilerRevealed)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _spoilerRevealed = true),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.visibility_off_outlined, color: scheme.outline),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('Contains spoilers — tap to show')),
                    ],
                  ),
                ),
              )
            else ...[
              Text(
                review,
                style: text.bodyMedium?.copyWith(height: 1.5),
                maxLines: _expanded ? null : 6,
                overflow: _expanded ? null : TextOverflow.fade,
              ),
              if (review.length > 300)
                TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(_expanded ? 'Show less' : 'Show more'),
                ),
            ],

            const SizedBox(height: 16),

            // ---- Dates (filled automatically when you change lists) ----
            DefaultTextStyle(
              style: text.bodySmall!.copyWith(color: scheme.outline),
              child: Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  Text('Added ${formatDate(entry.addedAt, dateStyle)}'),
                  if (entry.startedAt != null)
                    Text('Started ${formatDate(entry.startedAt!, dateStyle)}'),
                  if (entry.finishedAt != null)
                    Text('Finished ${formatDate(entry.finishedAt!, dateStyle)}'),
                  if (entry.reviewedAt != null)
                    Text('Reviewed ${formatDate(entry.reviewedAt!, dateStyle)}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
