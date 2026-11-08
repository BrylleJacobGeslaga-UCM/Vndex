import 'package:flutter/material.dart';

import '../../../models/vn.dart';

/// Top VNDB tags as chips. Sexual-content tags are hidden behind a toggle.
class TagSection extends StatefulWidget {
  const TagSection({super.key, required this.tags});

  final List<VnTag> tags;

  @override
  State<TagSection> createState() => _TagSectionState();
}

class _TagSectionState extends State<TagSection> {
  bool _showSexual = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final hiddenCount = widget.tags.where((t) => t.isSexual).length;
    final visible = [
      for (final t in widget.tags)
        if (_showSexual || !t.isSexual) t,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tags', style: text.titleMedium),
        const SizedBox(height: 8),
        if (widget.tags.isEmpty)
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
                Chip(
                  label: Text(t.name),
                  visualDensity: VisualDensity.compact,
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
