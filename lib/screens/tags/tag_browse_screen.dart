import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/add_to_list_sheet.dart';
import '../../core/widgets/list_badge.dart';
import '../../data/remote/vndb_api.dart';
import '../../models/vn.dart';
import '../../providers/providers.dart';
import '../detail/detail_screen.dart';
import '../search/widgets/vn_result_tile.dart';

/// Browse VNs that share tags.
///
/// [selected] tags are required (results must have ALL of them).
/// [suggested] tags can be tapped to add them and narrow the results.
/// Opened from a tag chip (one tag selected) or from "Find similar"
/// (the VN's top tags selected, and that VN excluded).
class TagBrowseScreen extends ConsumerStatefulWidget {
  const TagBrowseScreen({
    super.key,
    required this.selected,
    this.suggested = const [],
    this.excludeVnId,
    this.title,
  });

  final List<VnTag> selected;
  final List<VnTag> suggested;
  final String? excludeVnId;
  final String? title;

  @override
  ConsumerState<TagBrowseScreen> createState() => _TagBrowseScreenState();
}

enum _Sort {
  rating('rating', 'Top rated'),
  popular('votecount', 'Most popular');

  const _Sort(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

class _TagBrowseScreenState extends ConsumerState<TagBrowseScreen> {
  late final List<VnTag> _allTags; // selected first, then suggestions
  late final Set<String> _selectedIds;
  _Sort _sort = _Sort.rating;

  final List<Vn> _results = [];
  int _page = 0;
  bool _more = true;
  bool _loading = false;
  String? _error;

  /// Bumped on every reload; late responses from old filters are ignored.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    final seen = <String>{};
    _allTags = [
      for (final t in [...widget.selected, ...widget.suggested])
        if (t.id != null && seen.add(t.id!)) t,
    ];
    _selectedIds = {
      for (final t in widget.selected)
        if (t.id != null) t.id!,
    };
    // First page after the screen is built.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNextPage());
  }

  void _reload() {
    _requestId++;
    setState(() {
      _results.clear();
      _page = 0;
      _more = true;
      _error = null;
      _loading = false;
    });
    _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    if (_loading || !_more || _selectedIds.isEmpty) return;
    final id = _requestId;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final page = await ref.read(vnRepositoryProvider).browseByTags(
            _selectedIds.toList(),
            sort: _sort.apiValue,
            excludeId: widget.excludeVnId,
            page: _page + 1,
          );
      if (!mounted || id != _requestId) return;
      setState(() {
        _results.addAll(page.items);
        _page++;
        _more = page.more;
        _loading = false;
      });
    } on VndbException catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _toggleTag(VnTag tag) {
    final id = tag.id!;
    // Keep at least one tag selected.
    if (_selectedIds.contains(id) && _selectedIds.length == 1) return;
    setState(() {
      _selectedIds.contains(id) ? _selectedIds.remove(id) : _selectedIds.add(id);
    });
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final selectedNames = [
      for (final t in _allTags)
        if (_selectedIds.contains(t.id)) t.name,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title ?? selectedNames.join(' + '),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          PopupMenuButton<_Sort>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            initialValue: _sort,
            onSelected: (s) {
              if (s == _sort) return;
              _sort = s;
              _reload();
            },
            itemBuilder: (_) => [
              for (final s in _Sort.values)
                PopupMenuItem(value: s, child: Text(s.label)),
            ],
          ),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        // Load the next page when you get near the bottom.
        onNotification: (n) {
          if (n.metrics.extentAfter < 400) _loadNextPage();
          return false;
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildTagFilter()),
            if (_results.isEmpty && !_more && _error == null)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('No VNs have all these tags.')),
              ),
            SliverList.separated(
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 92),
              itemBuilder: (context, i) {
                final vn = _results[i];
                return VnResultTile(
                  vn: vn,
                  trailing: ListBadge(vnId: vn.id),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => DetailScreen(vn: vn)),
                  ),
                  onLongPress: () => showAddToListSheet(context, vn),
                );
              },
            ),
            SliverToBoxAdapter(child: _buildFooter()),
          ],
        ),
      ),
    );
  }

  Widget _buildTagFilter() {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_allTags.length > 1)
            Text(
              'Tap tags to narrow or widen the results',
              style: text.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in _allTags)
                FilterChip(
                  label: Text(t.name),
                  selected: _selectedIds.contains(t.id),
                  onSelected: (_) => _toggleTag(t),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Sorted by ${_sort.label.toLowerCase()}', style: text.labelSmall),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(_error!, textAlign: TextAlign.center),
            TextButton(onPressed: _loadNextPage, child: const Text('Retry')),
          ],
        ),
      );
    }
    return const SizedBox(height: 24);
  }
}
