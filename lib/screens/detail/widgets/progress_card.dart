import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/format.dart';
import '../../../data/repository/vn_repository.dart';
import '../../../models/user_entry.dart';
import '../../../providers/providers.dart';

/// "Your progress": score, notes and dates. Only shown for VNs in a list.
class ProgressCard extends ConsumerStatefulWidget {
  const ProgressCard({super.key, required this.entry});

  final UserEntry entry;

  @override
  ConsumerState<ProgressCard> createState() => _ProgressCardState();
}

class _ProgressCardState extends ConsumerState<ProgressCard> {
  late final TextEditingController _note;
  late final VnRepository _repo;
  Timer? _saveTimer;

  /// Score while the slider is being dragged; saved when you let go.
  int? _dragScore;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    // Grab the repository now: `ref` can't be used inside dispose().
    _repo = ref.read(vnRepositoryProvider);
    // Set once; later rebuilds don't reset what you're typing.
    _note = TextEditingController(text: widget.entry.progressNote ?? '');
  }

  @override
  void dispose() {
    // Save anything still waiting when you leave the screen.
    if (_saveTimer?.isActive ?? false) {
      _saveTimer!.cancel();
      _repo.setNote(widget.entry.vnId, _note.text);
    }
    _note.dispose();
    super.dispose();
  }

  /// Auto-save the note 800 ms after you stop typing.
  void _onNoteChanged(String _) {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 800), () {
      _repo.setNote(widget.entry.vnId, _note.text);
    });
  }

  Future<void> _setScore(int? score) async {
    await _repo.setScore(widget.entry.vnId, score);
    ref.invalidate(userEntryProvider(widget.entry.vnId));
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.outline;
    final score = _dragging ? _dragScore : entry.score;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your progress', style: text.titleMedium),
            const SizedBox(height: 12),

            // Score
            Row(
              children: [
                Text('Score', style: text.bodyMedium),
                const Spacer(),
                Text(
                  score == null ? 'Not rated' : '$score / 10',
                  style: text.titleSmall,
                ),
                if (score != null)
                  IconButton(
                    tooltip: 'Clear score',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => _setScore(null),
                  ),
              ],
            ),
            Slider(
              value: (score ?? 0).toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              label: score == null ? '—' : '$score',
              // 0 means "not rated". Only save when the finger lifts.
              onChangeStart: (_) => setState(() {
                _dragging = true;
                _dragScore = entry.score;
              }),
              onChanged: (v) =>
                  setState(() => _dragScore = v == 0 ? null : v.round()),
              onChangeEnd: (v) async {
                await _setScore(v == 0 ? null : v.round());
                if (mounted) setState(() => _dragging = false);
              },
            ),

            // Notes
            TextField(
              controller: _note,
              onChanged: _onNoteChanged,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Progress note',
                hintText: 'e.g. Kurisu route, chapter 6',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Dates (filled automatically when you change lists)
            DefaultTextStyle(
              style: text.bodySmall!.copyWith(color: muted),
              child: Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  Text('Added ${formatDate(entry.addedAt)}'),
                  if (entry.startedAt != null)
                    Text('Started ${formatDate(entry.startedAt!)}'),
                  if (entry.finishedAt != null)
                    Text('Finished ${formatDate(entry.finishedAt!)}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
