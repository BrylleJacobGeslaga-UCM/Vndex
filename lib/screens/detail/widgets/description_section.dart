import 'package:flutter/material.dart';

import '../../../core/utils/format.dart';

/// VN description with "Show more". Spoilers and markup are removed.
class DescriptionSection extends StatefulWidget {
  const DescriptionSection({super.key, required this.raw});

  final String? raw;

  @override
  State<DescriptionSection> createState() => _DescriptionSectionState();
}

class _DescriptionSectionState extends State<DescriptionSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final raw = widget.raw;
    final body = raw == null ? '' : cleanVndbText(raw);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Description', style: text.titleMedium),
        const SizedBox(height: 8),
        if (body.isEmpty)
          Text(
            'No description on VNDB.',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          )
        else ...[
          Text(
            body,
            style: text.bodyMedium?.copyWith(height: 1.5),
            maxLines: _expanded ? null : 6,
            overflow: _expanded ? null : TextOverflow.fade,
          ),
          // Only offer "Show more" when the text is actually long.
          if (body.length > 300)
            TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? 'Show less' : 'Show more'),
            ),
        ],
      ],
    );
  }
}
