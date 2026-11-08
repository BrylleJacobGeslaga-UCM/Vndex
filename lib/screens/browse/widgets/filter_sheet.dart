import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../data/remote/vndb_api.dart';
import '../../../models/browse_filter.dart';
import '../../../providers/providers.dart';

/// Opens the filter sheet. Returns the new filter, or null if dismissed.
/// [suggestedTags] (e.g. a VN's other tags) are offered as one-tap filters.
Future<BrowseFilter?> showFilterSheet(
  BuildContext context, {
  required BrowseFilter current,
  List<TagRef> suggestedTags = const [],
}) {
  return showModalBottomSheet<BrowseFilter>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      builder: (context, scroll) => FilterSheet(
        initial: current,
        suggestedTags: suggestedTags,
        scrollController: scroll,
      ),
    ),
  );
}

/// Full filter editor: Reset · Save · Filter, saved searches, then
/// collapsible sections. Edits a draft; nothing applies until "Filter".
class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({
    super.key,
    required this.initial,
    required this.suggestedTags,
    required this.scrollController,
  });

  final BrowseFilter initial;
  final List<TagRef> suggestedTags;
  final ScrollController scrollController;

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  late BrowseFilter _draft = widget.initial;

  // Tag search
  final _tagQuery = TextEditingController();
  Timer? _tagDebounce;
  List<TagRef> _tagResults = [];
  bool _tagLoading = false;

  @override
  void dispose() {
    _tagDebounce?.cancel();
    _tagQuery.dispose();
    super.dispose();
  }

  void _update(BrowseFilter f) => setState(() => _draft = f);

  Set<T> _toggled<T>(Set<T> set, T value) =>
      set.contains(value) ? ({...set}..remove(value)) : {...set, value};

  // ---------- Tags: tap cycles include → exclude → off ----------

  void _cycleTag(TagRef tag) {
    final inc = [..._draft.includeTags];
    final exc = [..._draft.excludeTags];
    if (inc.contains(tag)) {
      inc.remove(tag);
      exc.add(tag);
    } else if (exc.contains(tag)) {
      exc.remove(tag);
    } else {
      inc.add(tag);
    }
    _update(_draft.copyWith(includeTags: inc, excludeTags: exc));
  }

  void _onTagQueryChanged(String text) {
    _tagDebounce?.cancel();
    _tagDebounce = Timer(AppConstants.searchDebounce, () async {
      final q = text.trim();
      if (q.length < 2) {
        setState(() => _tagResults = []);
        return;
      }
      setState(() => _tagLoading = true);
      try {
        final results = await ref.read(vnRepositoryProvider).searchTags(q);
        if (!mounted || _tagQuery.text.trim() != q) return;
        setState(() {
          _tagResults = results;
          _tagLoading = false;
        });
      } on VndbException {
        if (mounted) setState(() => _tagLoading = false);
      }
    });
  }

  // ---------- Saved searches ----------

  Future<void> _saveCurrent() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save search'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Name, e.g. "Short mysteries"'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty) return;

    await ref.read(vnRepositoryProvider).saveSearch(name.trim(), _draft);
    ref.invalidate(savedSearchesProvider);
  }

  Future<void> _deleteSaved(SavedSearch s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${s.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(vnRepositoryProvider).deleteSavedSearch(s.key);
    ref.invalidate(savedSearchesProvider);
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Header: Reset · Save · Filter
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
          child: Row(
            children: [
              TextButton(
                onPressed: () => _update(BrowseFilter(excludeVnId: _draft.excludeVnId)),
                child: const Text('Reset'),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Save search',
                icon: const Icon(Icons.save),
                onPressed: _saveCurrent,
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => Navigator.pop(context, _draft),
                child: const Text('Filter'),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: scheme.outlineVariant),
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              _savedSearches(),
              _section(
                'Sort',
                _draft.sort.label,
                _chips<BrowseSort>(
                  {for (final s in BrowseSort.values) s: s.label},
                  isSelected: (s) => _draft.sort == s,
                  onTap: (s) => _update(_draft.copyWith(sort: s)),
                ),
              ),
              _section(
                'Original language',
                _summary(_draft.languages.map((l) => FilterOptions.languages[l]!)),
                _chips<String>(
                  FilterOptions.languages,
                  isSelected: _draft.languages.contains,
                  onTap: (l) => _update(
                    _draft.copyWith(languages: _toggled(_draft.languages, l)),
                  ),
                ),
              ),
              _section(
                'Platform',
                _summary(_draft.platforms.map((p) => FilterOptions.platforms[p]!)),
                _chips<String>(
                  FilterOptions.platforms,
                  isSelected: _draft.platforms.contains,
                  onTap: (p) => _update(
                    _draft.copyWith(platforms: _toggled(_draft.platforms, p)),
                  ),
                ),
              ),
              _section(
                'Length',
                _summary(_draft.lengths.map((l) => FilterOptions.lengths[l]!)),
                _chips<int>(
                  FilterOptions.lengths,
                  isSelected: _draft.lengths.contains,
                  onTap: (l) =>
                      _update(_draft.copyWith(lengths: _toggled(_draft.lengths, l))),
                ),
              ),
              _section(
                'Development status',
                _summary(_draft.devStatus.map((d) => FilterOptions.devStatus[d]!)),
                _chips<int>(
                  FilterOptions.devStatus,
                  isSelected: _draft.devStatus.contains,
                  onTap: (d) => _update(
                    _draft.copyWith(devStatus: _toggled(_draft.devStatus, d)),
                  ),
                ),
              ),
              _section('Release year', _yearSummary(), _yearPicker()),
              _section(
                'Minimum rating',
                _draft.minRating == null ? 'Any' : '${_draft.minRating}+',
                _ratingSlider(),
              ),
              _section('Tags', _tagSummary(), _tagEditor(), startOpen: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _savedSearches() {
    final saved = ref.watch(savedSearchesProvider).maybeWhen(
          data: (s) => s,
          orElse: () => const <SavedSearch>[],
        );
    if (saved.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Saved searches', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Tap to use · long-press to delete',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in saved)
                GestureDetector(
                  onLongPress: () => _deleteSaved(s),
                  child: ActionChip(
                    label: Text(s.name),
                    onPressed: () => Navigator.pop(context, s.filter),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// One collapsible row like "Platform ⌄", with the current choice under it.
  Widget _section(String title, String summary, Widget body, {bool startOpen = false}) {
    return ExpansionTile(
      title: Text(title),
      subtitle: Text(
        summary,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12),
      ),
      initiallyExpanded: startOpen,
      shape: const Border(), // no lines when expanded
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      expandedAlignment: Alignment.centerLeft,
      children: [body],
    );
  }

  Widget _chips<T>(
    Map<T, String> options, {
    required bool Function(T) isSelected,
    required void Function(T) onTap,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final e in options.entries)
          FilterChip(
            label: Text(e.value),
            selected: isSelected(e.key),
            onSelected: (_) => onTap(e.key),
          ),
      ],
    );
  }

  String _summary(Iterable<String> picked) => picked.isEmpty ? 'Any' : picked.join(', ');

  String _yearSummary() {
    final f = _draft.yearFrom, t = _draft.yearTo;
    if (f == null && t == null) return 'Any';
    if (f != null && t != null) return f == t ? '$f' : '$f – $t';
    return f != null ? 'From $f' : 'Up to $t';
  }

  Widget _yearPicker() {
    final thisYear = DateTime.now().year;
    final years = [for (var y = thisYear + 1; y >= 1990; y--) y];

    Widget dropdown(String label, int? value, void Function(int?) onChanged) =>
        Expanded(
          child: DropdownButtonFormField<int?>(
            value: value,
            decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
            items: [
              const DropdownMenuItem(value: null, child: Text('Any')),
              for (final y in years) DropdownMenuItem(value: y, child: Text('$y')),
            ],
            onChanged: onChanged,
          ),
        );

    return Row(
      children: [
        dropdown('From', _draft.yearFrom, (y) => _update(_draft.copyWith(yearFrom: () => y))),
        const SizedBox(width: 12),
        dropdown('To', _draft.yearTo, (y) => _update(_draft.copyWith(yearTo: () => y))),
      ],
    );
  }

  Widget _ratingSlider() {
    final r = _draft.minRating ?? 0;
    return Slider(
      value: r.toDouble(),
      min: 0,
      max: 9,
      divisions: 9,
      label: r == 0 ? 'Any' : '$r+',
      onChanged: (v) => _update(
        _draft.copyWith(minRating: () => v == 0 ? null : v.round()),
      ),
    );
  }

  String _tagSummary() {
    final inc = _draft.includeTags.length, exc = _draft.excludeTags.length;
    if (inc == 0 && exc == 0) return 'Any';
    return [if (inc > 0) '$inc included', if (exc > 0) '$exc excluded'].join(', ');
  }

  Widget _tagEditor() {
    final scheme = Theme.of(context).colorScheme;
    final picked = [..._draft.includeTags, ..._draft.excludeTags];
    final suggestions = [
      for (final t in widget.suggestedTags)
        if (!picked.contains(t)) t,
    ];
    final searchResults = [
      for (final t in _tagResults)
        if (!picked.contains(t)) t,
    ];

    Widget tagChip(TagRef t) {
      final included = _draft.includeTags.contains(t);
      final excluded = _draft.excludeTags.contains(t);
      return FilterChip(
        label: Text(t.name),
        selected: included || excluded,
        showCheckmark: false,
        avatar: included
            ? const Icon(Icons.check, size: 18)
            : excluded
                ? Icon(Icons.block, size: 18, color: scheme.error)
                : null,
        selectedColor: excluded ? scheme.errorContainer : null,
        onSelected: (_) => _cycleTag(t),
      );
    }

    Widget group(String label, List<TagRef> tags) => tags.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 6),
                Wrap(spacing: 8, runSpacing: 8, children: [for (final t in tags) tagChip(t)]),
              ],
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tap a tag: ✓ must have → ⊘ must not have → off',
          style: TextStyle(fontSize: 12, color: scheme.outline),
        ),
        group('Selected', picked),
        group('From this VN', suggestions),
        const SizedBox(height: 12),
        TextField(
          controller: _tagQuery,
          onChanged: _onTagQueryChanged,
          decoration: InputDecoration(
            hintText: 'Search tags, e.g. "time travel"',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _tagLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : null,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        group('Results', searchResults),
      ],
    );
  }
}
