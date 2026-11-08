import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/vn.dart';
import '../../../models/browse_filter.dart';
import '../../../providers/providers.dart';
import '../../browse/browse_screen.dart';

/// Top VNDB tags as tappable chips, plus "Find similar VNs".
/// Sexual-content tags are hidden behind a toggle, unless Settings →
/// Content says to always show them.
class TagSection extends ConsumerStatefulWidget {
  const TagSection({super.key, required this.vn});

  final Vn vn;

  @override
  ConsumerState<TagSection> createState() => _TagSectionState();
}

class _TagSectionState extends ConsumerState<TagSection> {
  bool _showSexual = false;

  List<VnTag> get _browsable =>
      [for (final t in widget.vn.tags) if (t.id != null) t];

  /// Other tags of this VN (non-sexual), offered in the filter sheet.
  List<TagRef> _suggestionsExcept(Iterable<VnTag> chosen) {
    final ids = {for (final t in chosen) t.id};
    return [
      for (final t in _browsable)
        if (!t.isSexual && !ids.contains(t.id)) TagRef.fromVnTag(t),
    ];
  }

  void _openTag(VnTag tag) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BrowseScreen(
        title: 'Tag: ${tag.name}',
        initialFilter: BrowseFilter(
          sort: BrowseSort.rating,
          includeTags: [TagRef.fromVnTag(tag)],
        ),
        suggestedTags: _suggestionsExcept([tag]),
      ),
    ));
  }

  void _openSimilar() {
    // Start with the 3 most relevant non-sexual tags, and hide this VN.
    final top = [for (final t in _browsable) if (!t.isSexual) t].take(3).toList();
    if (top.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BrowseScreen(
        title: 'Similar to ${widget.vn.title}',
        initialFilter: BrowseFilter(
          sort: BrowseSort.rating,
          includeTags: [for (final t in top) TagRef.fromVnTag(t)],
          excludeVnId: widget.vn.id,
        ),
        suggestedTags: _suggestionsExcept(top),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tags = widget.vn.tags;
    final alwaysShow = ref.watch(settingsProvider).showSexualTags;
    final showSexual = alwaysShow || _showSexual;
    final hiddenCount = alwaysShow ? 0 : tags.where((t) => t.isSexual).length;
    final visible = [
      for (final t in tags)
        if (showSexual || !t.isSexual) t,
    ];
    final canFindSimilar = _browsable.any((t) => !t.isSexual);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Tags', style: text.titleMedium),
            const Spacer(),
            if (canFindSimilar)
              TextButton.icon(
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Find similar'),
                onPressed: _openSimilar,
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (tags.isEmpty)
          Text(
            'No tags yet.',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in visible)
                ActionChip(
                  label: Text(t.name),
                  visualDensity: VisualDensity.compact,
                  // Old saved tags without an id can't be browsed.
                  onPressed: t.id == null ? null : () => _openTag(t),
                ),
            ],
          ),
        if (hiddenCount > 0)
          TextButton(
            onPressed: () => setState(() => _showSexual = !_showSexual),
            child: Text(_showSexual
                ? 'Hide sexual content tags'
                : 'Show $hiddenCount hidden sexual content tags'),
          ),
      ],
    );
  }
}
