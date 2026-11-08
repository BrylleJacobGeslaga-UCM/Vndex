import 'package:flutter/material.dart';

import '../../../core/widgets/sensitive_image.dart';
import '../../../models/library_prefs.dart';
import '../../../models/user_entry.dart';
import '../../../models/vn_status.dart';

/// Your VNs as a grid of covers, in one of the three grid styles.
class LibraryGrid extends StatelessWidget {
  const LibraryGrid({
    super.key,
    required this.entries,
    required this.prefs,
    required this.showStatus,
    required this.onTap,
    required this.onLongPress,
  });

  final List<LibraryEntry> entries;
  final LibraryPrefs prefs;
  final bool showStatus; // true in the "All" tab (and the overlay is on)
  final void Function(LibraryEntry) onTap;
  final void Function(LibraryEntry) onLongPress;

  @override
  Widget build(BuildContext context) {
    final comfortable = prefs.display == LibraryDisplay.comfortableGrid;
    // Comfortable grid needs extra height under the cover for the title.
    final aspect = comfortable ? 0.52 : 0.7;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: prefs.gridColumns,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: aspect,
      ),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final e = entries[i];
        return _GridTile(
          entry: e,
          prefs: prefs,
          showStatus: showStatus,
          onTap: () => onTap(e),
          onLongPress: () => onLongPress(e),
        );
      },
    );
  }
}

class _GridTile extends StatelessWidget {
  const _GridTile({
    required this.entry,
    required this.prefs,
    required this.showStatus,
    required this.onTap,
    required this.onLongPress,
  });

  final LibraryEntry entry;
  final LibraryPrefs prefs;
  final bool showStatus;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final vn = entry.vn;
    final scheme = Theme.of(context).colorScheme;
    final small = prefs.gridColumns >= 4; // fewer words when tiles are tiny

    final cover = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          vn.imageUrl == null
              ? Container(
                  color: scheme.surfaceContainerHighest,
                  child: Icon(Icons.image_not_supported_outlined, color: scheme.outline),
                )
              : SensitiveImage(
                  url: vn.imageUrl!,
                  sensitive: vn.isCoverSensitive,
                  onTap: onTap,
                ),

          // Compact grid: title on the cover over a dark fade.
          if (prefs.display == LibraryDisplay.compactGrid)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                  child: Text(
                    vn.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: small ? 11 : 14,
                    ),
                  ),
                ),
              ),
            ),

          // Score, top left (like the chapter count in your screenshot).
          if (prefs.showScore && entry.entry.score != null)
            Positioned(
              top: 6,
              left: 6,
              child: _CornerBadge(
                color: scheme.primary,
                child: Text(
                  '★${entry.entry.score}',
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: small ? 10 : 12,
                  ),
                ),
              ),
            ),

          // Which list, top right ("All" tab).
          if (showStatus)
            Positioned(
              top: 6,
              right: 6,
              child: _CornerBadge(
                color: entry.entry.status.color,
                child: small
                    ? Icon(entry.entry.status.icon, size: 12, color: Colors.white)
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(entry.entry.status.icon, size: 12, color: Colors.white),
                          const SizedBox(width: 3),
                          Text(
                            entry.entry.status.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
        ],
      ),
    );

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: prefs.display == LibraryDisplay.comfortableGrid
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cover),
                const SizedBox(height: 6),
                Text(
                  vn.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            )
          : cover,
    );
  }
}

class _CornerBadge extends StatelessWidget {
  const _CornerBadge({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: child,
    );
  }
}
