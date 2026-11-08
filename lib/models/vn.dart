/// A visual novel as returned by VNDB.
///
/// Only the fields Vndex asks for are here. If you add a field, also add it
/// to the `fields` string in vndb_api.dart, or VNDB won't send it.
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

  factory Vn.fromJson(Map<String, dynamic> json) {
    final image = json['image'] as Map<String, dynamic>?;
    final devs = (json['developers'] as List<dynamic>?) ?? const [];

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
    );
  }
}
