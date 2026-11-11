import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/sensitive_image.dart';
import '../../../models/quote.dart';
import '../../../providers/providers.dart';

/// Memorable lines from the VN, styled as quotes: the line in italics with
/// an accent bar, and "— Character" underneath. Best-voted lines come first
/// (VNDB's ranking), but no scores are shown. Hidden when there are none.
class QuoteSection extends ConsumerStatefulWidget {
  const QuoteSection({super.key, required this.vnId});

  final String vnId;

  @override
  ConsumerState<QuoteSection> createState() => _QuoteSectionState();
}

class _QuoteSectionState extends ConsumerState<QuoteSection> {
  int _visible = 4;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.outline;

    return ref.watch(vnQuotesProvider(widget.vnId)).when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => Row(
            children: [
              Expanded(child: Text('Could not load quotes.', style: TextStyle(color: muted))),
              TextButton(
                onPressed: () => ref.invalidate(vnQuotesProvider(widget.vnId)),
                child: const Text('Retry'),
              ),
            ],
          ),
          data: (quotes) {
            if (quotes.isEmpty) return const SizedBox.shrink();
            final shown = quotes.take(_visible).toList();
            final remaining = quotes.length - shown.length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Memorable quotes', style: text.titleMedium),
                const SizedBox(height: 12),
                for (final q in shown) _QuoteBlock(quote: q),
                if (remaining > 0)
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => _visible += 6),
                      child: Text('More quotes ($remaining)'),
                    ),
                  ),
              ],
            );
          },
        );
  }
}

class _QuoteBlock extends StatefulWidget {
  const _QuoteBlock({required this.quote});

  final VnQuote quote;

  @override
  State<_QuoteBlock> createState() => _QuoteBlockState();
}

class _QuoteBlockState extends State<_QuoteBlock> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.quote;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final hidden = q.spoilerCharacter && !_revealed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
          border: Border(left: BorderSide(color: scheme.primary, width: 3)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: hidden
            ? InkWell(
                onTap: () => setState(() => _revealed = true),
                child: Row(
                  children: [
                    Icon(Icons.visibility_off_outlined, size: 18, color: scheme.outline),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Spoiler character — tap to show',
                        style: text.bodyMedium?.copyWith(color: scheme.outline),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.text,
                    style: text.bodyLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Attribution: "— Okabe Rintarou"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (q.imageUrl != null) ...[
                        ClipOval(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: SensitiveImage(
                              url: q.imageUrl!,
                              sensitive: q.imageSensitive,
                              alignment: Alignment.topCenter,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          '— ${q.characterName ?? 'Unknown'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelLarge?.copyWith(color: scheme.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
