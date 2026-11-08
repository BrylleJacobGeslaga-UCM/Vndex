import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';

/// Small chip showing which list a VN is already in (nothing if none).
class ListBadge extends ConsumerWidget {
  const ListBadge({super.key, required this.vnId});

  final String vnId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(userEntryProvider(vnId)).maybeWhen(
          data: (entry) => entry?.status,
          orElse: () => null,
        );
    if (status == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: scheme.onSecondaryContainer),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(fontSize: 12, color: scheme.onSecondaryContainer),
          ),
        ],
      ),
    );
  }
}
