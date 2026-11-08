import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/widgets/add_to_list_sheet.dart';
import '../../core/widgets/list_badge.dart';
import '../../core/widgets/vn_result_tile.dart';
import '../../data/remote/vndb_api.dart';
import '../../models/browse_filter.dart';
import '../../models/vn.dart';
import '../../providers/providers.dart';
import '../detail/detail_screen.dart';
import 'widgets/filter_sheet.dart';

/// Which top chip is active.
enum _Mode { popular, latest, filter }

/// Browse VNDB: search bar, then Popular · Latest · Filter chips, then
/// results that keep loading as you scroll.
///
/// Open with [initialFilter] to start filtered, e.g. from a tag on a VN
/// page or "Find similar" (which also passes that VN's tags as
/// [suggestedTags] for the filter sheet).
class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({
    super.key,
    this.initialFilter,
    this.suggestedTags = const [],
    this.title,
  });

  final BrowseFilter? initialFilter;
  final List<TagRef> suggestedTags;
  final String? title;

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  late BrowseFilter _filter = widget.initialFilter ?? BrowseFilter.popular;
  late _Mode _mode = widget.initialFilter == null ? _Mode.popular : _Mode.filter;

  final _query = TextEditingController();
  Timer? _debounce;
  String _activeQuery = '';

  final List<Vn> _results = [];
  int _page = 0;
  bool _more = true;
  bool _loading = false;
  String? _error;

  /// Bumped on every reload; late responses from old searches are ignored.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNextPage());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  // ---------- Loading ----------

  void _reload() {
    _requestId++;
    setState(() {
      _results.clear();
      _page = 0;
      _more = true;
      _loading = false;
      _error = null;
    });
    _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    if (_loading || !_more) return;
    final id = _requestId;
    setState(() {
      _loading = true;
      _error = null;
    });

    // Typing a title under Popular/Latest sorts by best match instead.
    final byRelevance = _activeQuery.isNotEmpty && _mode != _Mode.filter;

    try {
      final page = await ref.read(vnRepositoryProvider).browse(
            filters: _filter.toVndbFilters(query: _activeQuery),
            sort: byRelevance ? 'searchrank' : _filter.sort.apiValue,
            reverse: byRelevance ? false : _filter.sort.reverse,
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

  // ---------- Inputs ----------

  void _onQueryChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(AppConstants.searchDebounce, () => _applyQuery(text));
  }

  void _applyQuery(String text) {
    final q = text.trim();
    if (q == _activeQuery || q.length == 1) return; // 1 letter is too broad
    _activeQuery = q;
    _reload();
  }

  void _setPreset(_Mode mode) {
    if (_mode == mode) return;
    _mode = mode;
    _filter = mode == _Mode.latest ? BrowseFilter.latest : BrowseFilter.popular;
    _reload();
  }

  Future<void> _openFilter() async {
    final result = await showFilterSheet(
      context,
      current: _filter,
      suggestedTags: widget.suggestedTags,
    );
    if (result == null) return;
    _filter = result;
    _mode = _Mode.filter;
    _reload();
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _query,
          autofocus: widget.initialFilter == null,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: widget.title ?? 'Search VNDB…',
            border: InputBorder.none,
          ),
          onChanged: _onQueryChanged,
          onSubmitted: (t) {
            _debounce?.cancel();
            _applyQuery(t);
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _ModeChips(
            mode: _mode,
            filterCount: _mode == _Mode.filter ? _filter.activeCount : 0,
            onPopular: () => _setPreset(_Mode.popular),
            onLatest: () => _setPreset(_Mode.latest),
            onFilter: _openFilter,
          ),
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        // Load the next page when you get near the bottom.
        onNotification: (n) {
          if (n.metrics.extentAfter < 400) _loadNextPage();
          return false;
        },
        child: _buildResults(),
      ),
    );
  }

  Widget _buildResults() {
    if (_results.isEmpty) {
      if (_loading) return const Center(child: CircularProgressIndicator());
      if (_error != null) return _message(Icons.cloud_off, _error!, retry: true);
      if (!_more) return _message(Icons.search_off, 'No VNs match.');
    }

    return ListView.separated(
      itemCount: _results.length + 1, // +1 for the footer
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 92),
      itemBuilder: (context, i) {
        if (i == _results.length) return _footer();
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
    );
  }

  Widget _footer() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(_error!, textAlign: TextAlign.center),
            TextButton(onPressed: _loadNextPage, child: const Text('Retry')),
          ],
        ),
      );
    }
    return const SizedBox(height: 32);
  }

  Widget _message(IconData icon, String text, {bool retry = false}) {
    final muted = Theme.of(context).colorScheme.outline;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: muted),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: TextStyle(color: muted)),
            if (retry) TextButton(onPressed: _loadNextPage, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

/// The Popular · Latest · Filter row.
class _ModeChips extends StatelessWidget {
  const _ModeChips({
    required this.mode,
    required this.filterCount,
    required this.onPopular,
    required this.onLatest,
    required this.onFilter,
  });

  final _Mode mode;
  final int filterCount;
  final VoidCallback onPopular;
  final VoidCallback onLatest;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, IconData icon, bool selected, VoidCallback onTap) =>
        FilterChip(
          label: Text(label),
          avatar: Icon(icon, size: 18),
          selected: selected,
          showCheckmark: false,
          onSelected: (_) => onTap(),
        );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          chip('Popular', Icons.favorite, mode == _Mode.popular, onPopular),
          const SizedBox(width: 8),
          chip('Latest', Icons.new_releases_outlined, mode == _Mode.latest, onLatest),
          const SizedBox(width: 8),
          chip(
            filterCount > 0 ? 'Filter ($filterCount)' : 'Filter',
            Icons.filter_list,
            mode == _Mode.filter,
            onFilter,
          ),
        ],
      ),
    );
  }
}
