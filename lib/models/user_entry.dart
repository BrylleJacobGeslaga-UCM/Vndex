import 'vn.dart';
import 'vn_status.dart';

/// Your own data about a VN: which list it's in, dates, score, notes.
class UserEntry {
  const UserEntry({
    required this.vnId,
    required this.status,
    this.score,
    this.review,
    this.reviewSpoiler = false,
    this.reviewedAt,
    this.startedAt,
    this.finishedAt,
    required this.addedAt,
    required this.updatedAt,
  });

  final String vnId;
  final VnStatus status;
  /// Stored 1–10 (VNDB's scale); shown as 0.5–5 stars (each half star = 1).
  final int? score;

  /// Your review of the VN. [reviewSpoiler] hides it behind a tap.
  final String? review;
  final bool reviewSpoiler;
  final DateTime? reviewedAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final DateTime addedAt;
  final DateTime updatedAt;

  factory UserEntry.fromDb(Map<String, Object?> row) {
    DateTime? date(String key) {
      final v = row[key] as int?;
      return v == null ? null : DateTime.fromMillisecondsSinceEpoch(v);
    }

    return UserEntry(
      vnId: row['vn_id'] as String,
      status: VnStatus.fromDb(row['status'] as String),
      score: row['score'] as int?,
      // Old progress notes (before reviews existed) carry over as reviews.
      review: (row['review'] ?? row['progress_note']) as String?,
      reviewSpoiler: row['review_spoiler'] as bool? ?? false,
      reviewedAt: date('reviewed_at'),
      startedAt: date('started_at'),
      finishedAt: date('finished_at'),
      addedAt: date('added_at')!,
      updatedAt: date('updated_at')!,
    );
  }
}

/// A VN plus your entry for it — one row in a status list.
class LibraryEntry {
  const LibraryEntry({required this.vn, required this.entry});

  final Vn vn;
  final UserEntry entry;
}
