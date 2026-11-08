import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/vn_cover.dart';
import '../../models/user_entry.dart';
import '../../models/vn.dart';
import '../../providers/providers.dart';

/// Full-screen editor for your review of one VN.
/// Pops `true` when something was saved or deleted.
class ReviewEditorScreen extends ConsumerStatefulWidget {
  const ReviewEditorScreen({super.key, required this.vn, required this.entry});

  final Vn vn;
  final UserEntry entry;

  @override
  ConsumerState<ReviewEditorScreen> createState() => _ReviewEditorScreenState();
}

class _ReviewEditorScreenState extends ConsumerState<ReviewEditorScreen> {
  late final _text = TextEditingController(text: widget.entry.review ?? '');
  late bool _spoiler = widget.entry.reviewSpoiler;
  bool _saving = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _changed =>
      _text.text.trim() != (widget.entry.review ?? '') ||
      _spoiler != widget.entry.reviewSpoiler;

  Future<void> _save({bool delete = false}) async {
    setState(() => _saving = true);
    await ref.read(vnRepositoryProvider).setReview(
          widget.entry.vnId,
          delete ? '' : _text.text,
          spoiler: _spoiler,
        );
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete review?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) _save(delete: true);
  }

  /// Ask before throwing away unsaved text.
  Future<bool> _confirmDiscard() async {
    if (!_changed) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep editing')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Discard')),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasExisting = widget.entry.review != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Your review'),
          actions: [
            if (hasExisting)
              IconButton(
                tooltip: 'Delete review',
                icon: const Icon(Icons.delete_outline),
                onPressed: _saving ? null : _confirmDelete,
              ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: _saving ? null : () => _save(),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            ListTile(
              leading: VnCover(vn: widget.vn, width: 36),
              title: Text(widget.vn.title, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            const Divider(height: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _text,
                  autofocus: !hasExisting,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}), // refresh the counter
                  decoration: const InputDecoration(
                    hintText: 'What did you think? Story, characters, routes, '
                        'music, who you\'d recommend it to…',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            SwitchListTile(
              secondary: Icon(Icons.visibility_off_outlined, color: scheme.primary),
              title: const Text('Contains spoilers'),
              subtitle: const Text('Hidden until tapped on the VN page'),
              value: _spoiler,
              onChanged: (v) => setState(() => _spoiler = v),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_text.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length} words',
                  style: TextStyle(fontSize: 12, color: scheme.outline),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
