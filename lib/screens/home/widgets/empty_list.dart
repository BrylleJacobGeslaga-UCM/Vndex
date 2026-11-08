import 'package:flutter/material.dart';

import '../../../models/vn_status.dart';

/// Shown when a status list has no entries yet.
class EmptyList extends StatelessWidget {
  const EmptyList({super.key, required this.status});

  final VnStatus status;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(
              'Nothing in ${status.label} yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Tap "Find a VN" to add one.',
              style: TextStyle(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
