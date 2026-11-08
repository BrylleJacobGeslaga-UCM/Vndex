import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants.dart';
import '../../models/browse_filter.dart';
import '../../models/vn.dart';

/// Thrown when a VNDB request fails, with a message safe to show the user.
class VndbException implements Exception {
  const VndbException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// One page of results plus whether VNDB has more after it.
class VnPage {
  const VnPage(this.items, {required this.more});
  final List<Vn> items;
  final bool more;
}

/// Talks to the VNDB Kana API. Screens should not use this directly;
/// go through providers (and later the repository).
class VndbApi {
  VndbApi({http.Client? client, this.baseUrl = AppConstants.vndbApiBase})
      : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  /// Fields for list/search results. VNDB needs every field named explicitly.
  static const String _listFields = 'title, alttitle, released, rating, '
      'length_minutes, image{url,sexual,violence}, developers{name}';

  /// Search VNs by title. Best matches first.
  Future<List<Vn>> searchVn(String query, {int results = 25}) async {
    final body = await _post('/vn', {
      'filters': ['search', '=', query],
      'fields': _listFields,
      'sort': 'searchrank',
      'results': results,
    });
    return _parseResults(body);
  }

  /// Extra fields for the detail screen.
  static const String _detailFields =
      '$_listFields, description, tags{id,name,rating,spoiler,lie,category}';

  /// Fetch one VN with full details (description, tags) by id, e.g. "v17".
  /// Returns null if it doesn't exist.
  Future<Vn?> getVnDetails(String id) async {
    final body = await _post('/vn', {
      'filters': ['id', '=', id],
      'fields': _detailFields,
    });
    final list = _parseResults(body);
    return list.isEmpty ? null : list.first;
  }

  /// Browse VNs with any VNDB filters (see BrowseFilter.toVndbFilters).
  /// [sort]: votecount, rating, released, title or searchrank.
  Future<VnPage> browse({
    required List<Object> filters,
    required String sort,
    bool reverse = true,
    int page = 1,
    int results = 25,
  }) async {
    final body = await _post('/vn', {
      // VNDB wants one filter; several are combined with "and".
      'filters': filters.isEmpty
          ? <Object>[]
          : filters.length == 1
              ? filters.first
              : ['and', ...filters],
      'fields': _listFields,
      'sort': sort,
      'reverse': reverse,
      'results': results,
      'page': page,
    });
    return VnPage(_parseResults(body), more: body['more'] as bool? ?? false);
  }

  /// Find tags by name, most used first. For the tag picker in Filter.
  Future<List<TagRef>> searchTags(String query) async {
    final body = await _post('/tag', {
      'filters': ['search', '=', query],
      'fields': 'name, category, vn_count',
      'sort': 'vn_count',
      'reverse': true,
      'results': 15,
    });
    return [
      for (final t in (body['results'] as List<dynamic>).cast<Map<String, dynamic>>())
        TagRef(
          id: t['id'] as String,
          name: t['name'] as String,
          category: t['category'] as String? ?? 'cont',
        ),
    ];
  }

  List<Vn> _parseResults(Map<String, dynamic> body) {
    final results = body['results'] as List<dynamic>;
    return [for (final r in results) Vn.fromJson(r as Map<String, dynamic>)];
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> query,
  ) async {
    final http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(query),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw const VndbException('Could not reach VNDB. Check your connection.');
    }

    switch (res.statusCode) {
      case 200:
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      case 429:
        throw const VndbException('Too many requests. Wait a moment and retry.');
      case 400:
        // Bad query — a bug on our side. The body says what VNDB didn't like.
        throw VndbException('Bad request: ${res.body}');
      default:
        throw VndbException('VNDB error ${res.statusCode}');
    }
  }
}
