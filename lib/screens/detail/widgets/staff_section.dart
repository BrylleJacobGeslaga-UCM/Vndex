import 'package:flutter/material.dart';

import '../../../models/browse_filter.dart';
import '../../../models/vn.dart';
import '../../browse/browse_screen.dart';

/// Key people behind a VN (director, writers, artists, composers).
/// Tap a name to browse everything that person worked on.
class StaffSection extends StatelessWidget {
  const StaffSection({super.key, required this.staff});

  final List<VnStaff> staff;

  @override
  Widget build(BuildContext context) {
    // Group by role, keep only the main roles, no duplicate names per role.
    final byRole = <String, List<VnStaff>>{};
    for (final s in staff) {
      if (!VnStaff.shownRoles.containsKey(s.role)) continue;
      final list = byRole.putIfAbsent(s.role, () => []);
      if (!list.any((x) => x.person.id == s.person.id)) list.add(s);
    }
    if (byRole.isEmpty) return const SizedBox.shrink();

    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.outline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Staff', style: text.titleMedium),
        const SizedBox(height: 8),
        for (final role in VnStaff.shownRoles.keys)
          if (byRole[role] case final people?)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        people.length > 1
                            ? '${VnStaff.shownRoles[role]}s'
                            : VnStaff.shownRoles[role]!,
                        style: text.bodySmall?.copyWith(color: muted),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        // Long credit lists (e.g. 12 artists) show the first 6.
                        for (final p in people.take(6))
                          ActionChip(
                            label: Text(p.person.name),
                            visualDensity: VisualDensity.compact,
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BrowseScreen(
                                  title: 'With ${p.person.name}',
                                  initialFilter: BrowseFilter(staff: p.person),
                                ),
                              ),
                            ),
                          ),
                        if (people.length > 6)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '+${people.length - 6} more',
                              style: text.bodySmall?.copyWith(color: muted),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
