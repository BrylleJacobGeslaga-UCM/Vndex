import 'package:flutter/material.dart';

/// The four lists in Vndex.
///
/// [dbValue] is what gets stored in SQLite — never rename it once data exists.
/// [vndbLabelId] maps to VNDB's built-in list labels, so account sync can be
/// added later without migrating data (1 Playing, 2 Finished, 4 Dropped,
/// 5 Wishlist).
enum VnStatus {
  playing('playing', 'Playing', Icons.play_circle_outline, 1),
  toPlay('to_play', 'To Play', Icons.bookmark_border, 5),
  finished('finished', 'Finished', Icons.check_circle_outline, 2),
  dropped('dropped', 'Dropped', Icons.cancel_outlined, 4);

  const VnStatus(this.dbValue, this.label, this.icon, this.vndbLabelId);

  final String dbValue;
  final String label;
  final IconData icon;
  final int vndbLabelId;

  /// Badge color in the "All" tab.
  Color get color => switch (this) {
        VnStatus.playing => const Color(0xFF4F8EF7), // blue
        VnStatus.toPlay => const Color(0xFFE0A33A), // amber
        VnStatus.finished => const Color(0xFF4CAF6A), // green
        VnStatus.dropped => const Color(0xFFE5534B), // red
      };

  static VnStatus fromDb(String value) =>
      VnStatus.values.firstWhere((s) => s.dbValue == value);
}
