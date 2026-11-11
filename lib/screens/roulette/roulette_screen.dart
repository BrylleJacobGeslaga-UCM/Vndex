import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/format.dart';
import '../../core/widgets/vn_cover.dart';
import '../../models/user_entry.dart';
import '../../models/vn_collection.dart';
import '../../models/vn_status.dart';
import '../../providers/providers.dart';
import '../detail/detail_screen.dart';

/// Length buckets for the roulette, using VNDB's length estimate.
enum _Length {
  any('Any'),
  short('Short < 10 h'),
  medium('10–30 h'),
  long('Long 30 h+');

  const _Length(this.label);
  final String label;

  /// VNs without a length estimate only count for "Any".
  bool allows(int? minutes) => switch (this) {
        _Length.any => true,
        _Length.short => minutes != null && minutes < 600,
        _Length.medium => minutes != null && minutes >= 600 && minutes <= 1800,
        _Length.long => minutes != null && minutes > 1800,
      };
}

/// "What should I play next?" — picks a random VN from your To Play list
/// (or a collection), with an optional length filter.
class RouletteScreen extends ConsumerStatefulWidget {
  const RouletteScreen({super.key});

  @override
  ConsumerState<RouletteScreen> createState() => _RouletteScreenState();
}

class _RouletteScreenState extends ConsumerState<RouletteScreen> {
  final _random = Random();

  /// null = To Play; otherwise a collection key.
  int? _collectionKey;
  _Length _length = _Length.any;
  bool _releasedOnly = true;

  LibraryEntry? _shown; // what's on screen (changes while spinning)
  LibraryEntry? _pick; // final result
  bool _spinning = false;

  List<LibraryEntry> _pool(List<LibraryEntry> source) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return [
      for (final e in source)
        if (_length.allows(e.vn.lengthMinutes) &&
            (!_releasedOnly ||
                (e.vn.released != null &&
                    e.vn.released != 'TBA' &&
                    e.vn.released!.compareTo(today) <= 0)))
          e,
    ];
  }

  void _resetPick() => setState(() {
        _pick = null;
        _shown = null;
      });

  Future<void> _spin(List<LibraryEntry> pool) async {
    if (pool.isEmpty || _spinning) return;

    // Don't land on the same VN twice in a row when there's a choice.
    final choices = pool.length > 1 && _pick != null
        ? [for (final e in pool) if (e.vn.id != _pick!.vn.id) e]
        : pool;
    final winner = choices[_random.nextInt(choices.length)];

    setState(() => _spinning = true);

    // Flick through random covers, slowing down, then land on the winner.
    if (pool.length > 1) {
      for (var i = 0; i < 14; i++) {
        await Future<void>.delayed(Duration(milliseconds: 45 + i * 14));
        if (!mounted) return;
        HapticFeedback.selectionClick();
        setState(() => _shown = pool[_random.nextInt(pool.length)]);
      }
      await Future<void>.delayed(const Duration(milliseconds: 260));
      if (!mounted) return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _shown = winner;
      _pick = winner;
      _spinning = false;
    });
  }

  Future<void> _startPlaying(LibraryEntry e) async {
    await ref.read(vnRepositoryProvider).setStatus(e.vn, VnStatus.playing);
    refreshLibrary(ref);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('${e.vn.title} moved to Playing. Have fun!')));
    _resetPick();
  }

  @override
  Widget build(BuildContext context) {
    final collections = ref.watch(collectionsProvider).maybeWhen(
          data: (c) => c,
          orElse: () => const <VnCollection>[],
        );
    // A deleted collection falls back to To Play.
    if (_collectionKey != null && !collections.any((c) => c.key == _collectionKey)) {
      _collectionKey = null;
    }

    final source = _collectionKey == null
        ? ref.watch(statusListProvider(VnStatus.toPlay))
        : ref.watch(collectionEntriesProvider(_collectionKey!));

    return Scaffold(
      appBar: AppBar(title: const Text('What should I play next?')),
      body: source.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load your list:\n$e')),
        data: (all) {
          final pool = _pool(all);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _options(collections),
              const SizedBox(height: 8),
              _poolSummary(pool),
              const SizedBox(height: 24),
              _result(pool),
            ],
          );
        },
      ),
    );
  }

  Widget _options(List<VnCollection> collections) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pick from', style: text.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              avatar: Icon(VnStatus.toPlay.icon, size: 18),
              label: const Text('To Play'),
              selected: _collectionKey == null,
              onSelected: _spinning
                  ? null
                  : (_) => setState(() {
                        _collectionKey = null;
                        _resetPick();
                      }),
            ),
            for (final c in collections)
              ChoiceChip(
                avatar: const Icon(Icons.folder_outlined, size: 18),
                label: Text(c.name),
                selected: _collectionKey == c.key,
                onSelected: _spinning
                    ? null
                    : (_) => setState(() {
                          _collectionKey = c.key;
                          _resetPick();
                        }),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Length', style: text.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final l in _Length.values)
              ChoiceChip(
                label: Text(l.label),
                selected: _length == l,
                onSelected: _spinning
                    ? null
                    : (_) => setState(() {
                          _length = l;
                          _resetPick();
                        }),
              ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Released only'),
          subtitle: const Text('Skip VNs that aren\'t out yet'),
          value: _releasedOnly,
          onChanged: _spinning
              ? null
              : (v) => setState(() {
                    _releasedOnly = v;
                    _resetPick();
                  }),
        ),
      ],
    );
  }

  /// "12 VNs in the pool · ~420 h total"
  Widget _poolSummary(List<LibraryEntry> pool) {
    final minutes = pool.fold<int>(0, (sum, e) => sum + (e.vn.lengthMinutes ?? 0));
    final unknown = pool.where((e) => e.vn.lengthMinutes == null).length;
    final parts = [
      '${pool.length} VN${pool.length == 1 ? '' : 's'} in the pool',
      if (minutes > 0) '~${(minutes / 60).round()} h total',
      if (unknown > 0 && minutes > 0) '($unknown without a length)',
    ];
    return Text(
      parts.join(' · '),
      style: TextStyle(color: Theme.of(context).colorScheme.outline),
    );
  }

  Widget _result(List<LibraryEntry> pool) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    if (pool.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.casino_outlined, size: 64, color: scheme.outline),
            const SizedBox(height: 12),
            Text(
              'Nothing matches. Try another length, or add VNs to To Play.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.outline),
            ),
          ],
        ),
      );
    }

    final shown = _shown;
    final pick = _pick;

    return Column(
      children: [
        // Cover area: a dice before the first spin, then flicking covers.
        SizedBox(
          height: 252,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 120),
              child: shown == null
                  ? Icon(Icons.casino, key: const ValueKey('dice'), size: 120, color: scheme.primary)
                  : VnCover(key: ValueKey(shown.vn.id), vn: shown.vn, width: 180),
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (pick != null && !_spinning) ...[
          Text(pick.vn.title, style: text.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            [
              if (pick.vn.releaseYear != null) pick.vn.releaseYear!,
              if (pick.vn.lengthMinutes != null) formatLength(pick.vn.lengthMinutes!),
              if (pick.vn.ratingLabel != null) '★ ${pick.vn.ratingLabel} on VNDB',
            ].join(' · '),
            style: TextStyle(color: scheme.outline),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (pick.entry.status != VnStatus.playing)
                FilledButton.icon(
                  icon: Icon(VnStatus.playing.icon),
                  label: const Text('Start playing'),
                  onPressed: () => _startPlaying(pick),
                ),
              OutlinedButton.icon(
                icon: const Icon(Icons.info_outline),
                label: const Text('Details'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => DetailScreen(vn: pick.vn)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            icon: const Icon(Icons.casino_outlined),
            label: Text(_spinning
                ? 'Picking…'
                : pick == null
                    ? 'Spin'
                    : 'Spin again'),
            onPressed: _spinning ? null : () => _spin(pool),
          ),
        ),
      ],
    );
  }
}
