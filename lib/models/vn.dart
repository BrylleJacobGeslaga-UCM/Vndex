import 'dart:convert';

/// One VNDB tag on a VN, e.g. "Time Travel" with a relevance of 2.6.
class VnTag {
  const VnTag({
    this.id,
    required this.name,
    required this.rating,
    required this.category,
  });

  /// VNDB tag id, e.g. "g7". Needed to browse VNs with this tag.
  /// Null only for tags saved before Step 7 (they refresh when online).
  final String? id;
  final String name;
  final double rating; // 0–3, how strongly the tag applies
  final String category; // "cont" content, "tech" technical, "ero" sexual

  bool get isSexual => category == 'ero';

  Map<String, Object?> toDb() =>
      {'id': id, 'name': name, 'rating': rating, 'category': category};

  factory VnTag.fromDb(Map<String, Object?> m) => VnTag(
        id: m['id'] as String?,
        name: m['name'] as String,
        rating: (m['rating'] as num).toDouble(),
        category: m['category'] as String? ?? 'cont',
      );
}

/// One screenshot. [sexual]/[violence] use VNDB's 0–2 scale.
class VnScreenshot {
  const VnScreenshot({
    required this.url,
    required this.thumbnail,
    this.sexual = 0,
    this.violence = 0,
  });

  final String url;
  final String thumbnail;
  final double sexual;
  final double violence;

  bool get isSensitive => sexual >= 1 || violence >= 1;

  factory VnScreenshot.fromJson(Map<String, dynamic> j) => VnScreenshot(
        url: j['url'] as String,
        thumbnail: (j['thumbnail'] as String?) ?? j['url'] as String,
        sexual: (j['sexual'] as num?)?.toDouble() ?? 0,
        violence: (j['violence'] as num?)?.toDouble() ?? 0,
      );
}

/// A developer (VNDB "producer"), e.g. "5pb." with id "p63".
/// [id] is null only for VNs saved before ids were stored; it fills in
/// when the VN page is opened online.
class VnDeveloper {
  const VnDeveloper({this.id, required this.name});

  final String? id;
  final String name;

  Map<String, Object?> toJson() => {'id': id, 'name': name};

  /// Accepts the old format (just a name) and the new one (id + name).
  factory VnDeveloper.fromStored(Object? v) => v is Map
      ? VnDeveloper(id: v['id'] as String?, name: v['name'] as String)
      : VnDeveloper(name: v as String);
}

/// A person credited on VNDB (writer, artist, composer…). Used to browse
/// everything they worked on.
class StaffRef {
  const StaffRef({required this.id, required this.name});

  final String id; // "s123"
  final String name;

  Map<String, Object?> toJson() => {'id': id, 'name': name};

  factory StaffRef.fromJson(Map<String, Object?> j) =>
      StaffRef(id: j['id'] as String, name: j['name'] as String);
}

/// One staff credit on a VN, e.g. Hayashi Chiyomaru as Scenario.
class VnStaff {
  const VnStaff({required this.person, required this.role, this.original});

  final StaffRef person;
  final String role; // VNDB code: "scenario", "music", ...
  final String? original; // name in the original script

  /// The roles shown on VN pages, in display order, with labels.
  static const shownRoles = {
    'director': 'Director',
    'scenario': 'Writer',
    'chardesign': 'Character design',
    'art': 'Artist',
    'music': 'Composer',
    'songs': 'Vocals',
  };
}

/// Another VN related to this one: prequel, sequel, fandisc, etc.
class VnRelation {
  const VnRelation({
    required this.vn,
    required this.type,
    required this.official,
  });

  final Vn vn;
  final String type; // VNDB code: "preq", "seq", "fan", ...
  final bool official; // false = fan-made or unofficial link

  static const _labels = {
    'preq': 'Prequel',
    'seq': 'Sequel',
    'par': 'Parent story',
    'side': 'Side story',
    'fan': 'Fandisc',
    'orig': 'Original game',
    'alt': 'Alternative version',
    'ser': 'Same series',
    'set': 'Same setting',
    'char': 'Shares characters',
  };

  /// Display order: story order first, loosely related last.
  static const _order = [
    'preq', 'seq', 'par', 'side', 'fan', 'orig', 'alt', 'ser', 'set', 'char',
  ];

  String get label => _labels[type] ?? 'Related';
  int get sortKey {
    final i = _order.indexOf(type);
    return i == -1 ? _order.length : i;
  }

  /// Prequels and sequels get highlighted.
  bool get isStoryOrder => type == 'preq' || type == 'seq';
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
    this.developerList = const [],
    this.description,
    this.tags = const [],
    this.screenshots = const [],
    this.relations = const [],
    this.staff = const [],
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
  final List<VnDeveloper> developerList;

  /// Just the names, e.g. for "2009 · 5pb.".
  List<String> get developers => [for (final d in developerList) d.name];

  /// Only loaded on the detail screen; null in search results.
  final String? description;

  /// Only loaded on the detail screen. Spoiler tags are already removed,
  /// sorted most relevant first.
  final List<VnTag> tags;

  /// Only loaded on the detail screen, and not saved offline (they're
  /// images from the internet anyway).
  final List<VnScreenshot> screenshots;

  /// Only loaded on the detail screen, not saved offline. Sorted with
  /// prequels and sequels first.
  final List<VnRelation> relations;

  /// Only loaded on the detail screen, not saved offline.
  final List<VnStaff> staff;

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
        'developers': jsonEncode([for (final d in developerList) d.toJson()]),
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
      developerList: devs == null
          ? const []
          : [for (final d in jsonDecode(devs) as List<dynamic>) VnDeveloper.fromStored(d)],
      description: row['description'] as String?,
      tags: [for (final t in tags) VnTag.fromDb(t as Map<String, Object?>)],
    );
  }

  factory Vn.fromJson(Map<String, dynamic> json) {
    final image = json['image'] as Map<String, dynamic>?;
    final devs = (json['developers'] as List<dynamic>?) ?? const [];
    final rawTags = (json['tags'] as List<dynamic>?) ?? const [];
    final rawShots = (json['screenshots'] as List<dynamic>?) ?? const [];
    final rawRelations = (json['relations'] as List<dynamic>?) ?? const [];
    final rawStaff = (json['staff'] as List<dynamic>?) ?? const [];

    final relations = [
      for (final r in rawRelations.cast<Map<String, dynamic>>())
        VnRelation(
          vn: Vn.fromJson(r),
          type: r['relation'] as String? ?? '',
          official: r['relation_official'] as bool? ?? true,
        ),
    ]..sort((a, b) {
        final byType = a.sortKey.compareTo(b.sortKey);
        if (byType != 0) return byType;
        // Same type: oldest release first (e.g. sequel 1 before sequel 2).
        return (a.vn.released ?? '9999').compareTo(b.vn.released ?? '9999');
      });

    // Keep only spoiler-free, non-disputed tags, most relevant first, max 20.
    final tags = [
      for (final t in rawTags.cast<Map<String, dynamic>>())
        if ((t['spoiler'] as num? ?? 0) == 0 && t['lie'] != true)
          VnTag(
            id: t['id'] as String?,
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
      developerList: [
        for (final d in devs.cast<Map<String, dynamic>>())
          VnDeveloper(id: d['id'] as String?, name: d['name'] as String),
      ],
      description: json['description'] as String?,
      tags: tags.take(20).toList(),
      screenshots: [
        for (final sc in rawShots.cast<Map<String, dynamic>>())
          VnScreenshot.fromJson(sc),
      ],
      relations: relations,
      staff: [
        for (final st in rawStaff.cast<Map<String, dynamic>>())
          if (st['id'] is String && st['name'] is String)
            VnStaff(
              person: StaffRef(id: st['id'] as String, name: st['name'] as String),
              role: st['role'] as String? ?? 'staff',
              original: st['original'] as String?,
            ),
      ],
    );
  }
}
