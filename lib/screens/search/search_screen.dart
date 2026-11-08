import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../data/remote/vndb_api.dart';
import '../../models/vn.dart';
import '../../providers/providers.dart';
import 'widgets/vn_result_tile.dart';

/// Search VNDB by title. Waits for the user to stop typing before calling
/// the API, so we stay well under VNDB's rate limit.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  List<Vn> _results = [];
  bool _loading = false;
  String? _error;
  String _lastQuery = '';

  /// Bumped on every search; older responses that arrive late are ignored.
  int _requestId = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(AppConstants.searchDebounce, () => _search(text));
  }

  Future<void> _search(String text) async {
    final query = text.trim();
    if (query == _lastQuery) return;
    _lastQuery = query;

    if (query.length < 2) {
      setState(() {
        _results = [];
        _error = null;
        _loading = false;
      });
      return;
    }

    final id = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await ref.read(vndbApiProvider).searchVn(query);
      if (!mounted || id != _requestId) return;
      setState(() {
        _results = results;
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

  void _retry() {
    _lastQuery = '';
    _search(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search VNDB…',
            border: InputBorder.none,
          ),
          onChanged: _onChanged,
          onSubmitted: (text) {
            _debounce?.cancel();
            _search(text);
          },
        ),
        bottom: _loading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return _Message(
        icon: Icons.cloud_off,
        text: _error!,
        action: TextButton(onPressed: _retry, child: const Text('Retry')),
      );
    }
    if (_lastQuery.length < 2) {
      return const _Message(
        icon: Icons.search,
        text: 'Type a title, e.g. "Steins;Gate"',
      );
    }
    if (_results.isEmpty && !_loading) {
      return _Message(icon: Icons.search_off, text: 'No results for "$_lastQuery"');
    }

    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 92),
      itemBuilder: (context, i) {
        final vn = _results[i];
        return VnResultTile(
          vn: vn,
          onTap: () {
            // Step 5: open a sheet to add this VN to one of the four lists.
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text('${vn.title} (${vn.id}) — adding comes next step'),
              ));
          },
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
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
            if (action != null) ...[const SizedBox(height: 8), action!],
          ],
        ),
      ),
    );
  }
}
