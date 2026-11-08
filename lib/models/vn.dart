import 'dart:convert';

/// One VNDB tag on a VN, e.g. "Time Travel" with a relevance of 2.6.
class VnTag {
  const VnTag({required this.name, required this.rating, required this.category});

  final String name;
  final double rating; // 0–3, how strongly the tag applies
  final String category; // "cont" content, "tech" technical, "ero" sexual

  bool get isSexual => category == 'ero';

  Map<String, Object?> toDb() =>
      {'name': name, 'rating': rating, 'category': category};

  factory VnTag.fromDb(Map<String, Object?> m) => VnTag(
        name: m['name'] as String,
        rating: (m['rating'] as num).toDouble(),
        category: m['category'] as String? ?? 'cont',
      );
}

/// A visual novel as returned by VNDB.
///
/// Only the fields Vndex asks for are here. If you add a field, also add it
/// to the `fields` strings in vndb_api.dart, or VNDB won't send it.
class Vn {
  const Vn({
    required this.id,
    required this.title,
    this.altTitle,
    this.released,
    this.rating,
    this.lengthMinutes,
    this.imageUrl,
    this.imageSexual = 0,
    this.imageViolence = 0,
    this.developers = const [],
    this.description,
    this.tags = const [],
  });

  final String id; // e.g. "v17"
  final String title;
  final String? altTitle; // usually the original Japanese title
  final String? released; // "2009-10-15", "2009", or "TBA"
  final double? rating; // 10–100, null if not enough votes
  final int? lengthMinutes;
  final String? imageUrl;
  final double imageSexual; // 0 safe, 1 suggestive, 2 explicit (average vote)
  final double imageViolence; // same scale
  final List<String> developers;

  /// Only loaded on the detail screen; null in search results.
  final String? description;

  /// Only loaded on the detail screen. Spoiler tags are already removed,
  /// sorted most relevant first.
  final List<VnTag> tags;

  /// Covers rated suggestive or worse get blurred until tapped.
  bool get isCoverSensitive => imageSexual >= 1 || imageViolence >= 1;

  /// "2009" from "2009-10-15", or null.
  String? get releaseYear {
    final r = released;
    if (r == null || r.length < 4 || r == 'TBA') return r;
    return r.substring(0, 4);
  }

  /// VNDB rating is 10–100; show it on the familiar 1–10 scale.
  String? get ratingLabel =>
      rating == null ? null : (rating! / 10).toStringAsFixed(1);

  /// Record for the local `vn` store. Description and tags are only written
  /// when we actually have them, so a search result (which has neither)
  /// never erases details saved earlier.
  Map<String, Object?> toDb({required int fetchedAt}) => {
        'id': id,
        'title': title,
        'alt_title': altTitle,
        'released': released,
        'rating': rating,
        'length_minutes': lengthMinutes,
        'image_url': imageUrl,
        'image_sexual': imageSexual,
        'image_violence': imageViolence,
        'developers': jsonEncode(developers),
        if (description != null) 'description': description,
        if (tags.isNotEmpty) 'tags': [for (final t in tags) t.toDb()],
        'last_fetched': fetchedAt,
      };

  /// Build from a local `vn` record.
  factory Vn.fromDb(Map<String, Object?> row) {
    final devs = row['developers'] as String?;
    final tags = (row['tags'] as List<Object?>?) ?? const [];
    return Vn(
      id: row['id'] as String,
      title: row['title'] as String,
      altTitle: row['alt_title'] as String?,
      released: row['released'] as String?,
      rating: (row['rating'] as num?)?.toDouble(),
      lengthMinutes: row['length_minutes'] as int?,
      imageUrl: row['image_url'] as String?,
      imageSexual: (row['image_sexual'] as num?)?.toDouble() ?? 0,
      imageViolence: (row['image_violence'] as num?)?.toDouble() ?? 0,
      developers: devs == null
          ? const []
          : (jsonDecode(devs) as List<dynamic>).cast<String>(),
      description: row['description'] as String?,
      tags: [for (final t in tags) VnTag.fromDb(t as Map<String, Object?>)],
    );
  }

  factory Vn.fromJson(Map<String, dynamic> json) {
    final image = json['image'] as Map<String, dynamic>?;
    final devs = (json['developers'] as List<dynamic>?) ?? const [];
    final rawTags = (json['tags'] as List<dynamic>?) ?? const [];

    // Keep only spoiler-free, non-disputed tags, most relevant first, max 20.
    final tags = [
      for (final t in rawTags.cast<Map<String, dynamic>>())
        if ((t['spoiler'] as num? ?? 0) == 0 && t['lie'] != true)
          VnTag(
            name: t['name'] as String,
            rating: (t['rating'] as num).toDouble(),
            category: t['category'] as String? ?? 'cont',
          ),
    ]..sort((a, b) => b.rating.compareTo(a.rating));

    return Vn(
      id: json['id'] as String,
      title: json['title'] as String,
      altTitle: json['alttitle'] as String?,
      released: json['released'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      lengthMinutes: json['length_minutes'] as int?,
      imageUrl: image?['url'] as String?,
      imageSexual: (image?['sexual'] as num?)?.toDouble() ?? 0,
      imageViolence: (image?['violence'] as num?)?.toDouble() ?? 0,
      developers: [
        for (final d in devs) (d as Map<String, dynamic>)['name'] as String,
      ],
      description: json['description'] as String?,
      tags: tags.take(20).toList(),
    );
  }
}
