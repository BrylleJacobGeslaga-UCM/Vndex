import 'package:flutter/material.dart';

/// Can you play this VN in English? Worked out from its VNDB releases.
enum EnglishKind {
  official('Official English release', Icons.verified_outlined),
  upcoming('Official English release coming', Icons.schedule),
  fan('Fan translation', Icons.translate),
  machine('Machine translation only', Icons.smart_toy_outlined),
  none('No English release', Icons.block);

  const EnglishKind(this.label, this.icon);
  final String label;
  final IconData icon;

  bool get isPlayable => this == official || this == fan;
}

class EnglishAvailability {
  const EnglishAvailability(this.kind, {this.date});

  final EnglishKind kind;

  /// For [EnglishKind.upcoming]: "2027-03-14", "2027" or "TBA".
  final String? date;

  /// Best option wins: official released > official upcoming > fan > machine.
  factory EnglishAvailability.fromReleases(List<Map<String, dynamic>> releases) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    var best = EnglishKind.none;
    String? upcomingDate;

    for (final r in releases) {
      final english = (r['languages'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .where((l) => l['lang'] == 'en');
      if (english.isEmpty) continue;

      final mtl = english.every((l) => l['mtl'] == true);
      final official = r['official'] == true;
      final released = r['released'] as String?;
      final isOut = released != null && released != 'TBA' && released.compareTo(today) <= 0;

      final kind = mtl
          ? EnglishKind.machine
          : official
              ? (isOut ? EnglishKind.official : EnglishKind.upcoming)
              : EnglishKind.fan;

      if (kind.index < best.index) best = kind;
      if (kind == EnglishKind.upcoming &&
          (upcomingDate == null || (released ?? 'TBA').compareTo(upcomingDate) < 0)) {
        upcomingDate = released ?? 'TBA';
      }
    }
    return EnglishAvailability(
      best,
      date: best == EnglishKind.upcoming ? upcomingDate : null,
    );
  }

  String get label =>
      kind == EnglishKind.upcoming && date != null ? '${kind.label} · $date' : kind.label;
}
