import 'vn.dart';
import 'vn_status.dart';

/// Your own data about a VN: which list it's in, dates, score, notes.
class UserEntry {
  const UserEntry({
    required this.vnId,
    required this.status,
    this.score,
    this.progressNote,
    this.startedAt,
    this.finishedAt,
    required this.addedAt,
    required this.updatedAt,
  });

  final String vnId;
  final VnStatus status;
  final int? score; // 1–10, set later from the detail screen
  final String? progressNote;
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
      progressNote: row['progress_note'] as String?,
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
