import 'package:flutter/material.dart';

/// Five stars with half steps. [value] is 0–10 (each half star = 1),
/// matching VNDB's 1–10 scale; null or 0 means "not rated".
///
/// Tap or drag across the stars to rate. Tapping the current rating
/// again clears it. Leave [onChanged] null for a read-only display.
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 36,
    this.color,
  });

  final int? value;
  final ValueChanged<int?>? onChanged;
  final double size;
  final Color? color;

  /// Which value (1–10) a finger at [dx] pixels from the left means.
  int _valueAt(double dx) {
    final halfSteps = (dx / (size / 2)).ceil();
    return halfSteps.clamp(1, 10);
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    final muted = Theme.of(context).colorScheme.outline;
    final v = value ?? 0;

    final stars = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            v >= i * 2
                ? Icons.star_rounded
                : v == i * 2 - 1
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded,
            size: size,
            color: v >= i * 2 - 1 ? c : muted,
          ),
      ],
    );

    final onChanged = this.onChanged;
    if (onChanged == null) return stars;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (d) {
        final tapped = _valueAt(d.localPosition.dx);
        onChanged(tapped == value ? null : tapped); // same again = clear
      },
      onHorizontalDragUpdate: (d) {
        final dragged = _valueAt(d.localPosition.dx);
        if (dragged != value) onChanged(dragged);
      },
      child: stars,
    );
  }
}
