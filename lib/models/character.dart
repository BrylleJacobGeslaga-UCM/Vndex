/// A character's role in one VN. Order = how important (used for sorting).
enum CharacterRole {
  main('Protagonist'),
  primary('Main character'),
  side('Side character'),
  appears('Makes an appearance');

  const CharacterRole(this.label);
  final String label;

  static CharacterRole fromApi(String? v) => switch (v) {
        'main' => CharacterRole.main,
        'primary' => CharacterRole.primary,
        'side' => CharacterRole.side,
        _ => CharacterRole.appears,
      };
}

/// A character as shown on a VN's page.
class VnCharacter {
  const VnCharacter({
    required this.id,
    required this.name,
    this.original,
    this.description,
    this.imageUrl,
    this.imageSexual = 0,
    this.imageViolence = 0,
    required this.role,
  });

  final String id; // "c17"
  final String name;
  final String? original; // name in the original script
  final String? description; // raw VNDB markup; clean before showing
  final String? imageUrl;
  final double imageSexual;
  final double imageViolence;
  final CharacterRole role;

  bool get isImageSensitive => imageSexual >= 1 || imageViolence >= 1;

  /// Returns null for characters that are a spoiler in [vnId]
  /// (VNDB spoiler level above 0), so they're never shown.
  static VnCharacter? fromJson(Map<String, dynamic> j, String vnId) {
    final vns = (j['vns'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .where((v) => v['id'] == vnId)
        .toList();
    if (vns.isEmpty) return null;

    // A character can be listed more than once (per release); use the
    // least spoilery, most important entry.
    final minSpoiler = vns
        .map((v) => (v['spoiler'] as num?)?.toInt() ?? 0)
        .reduce((a, b) => a < b ? a : b);
    if (minSpoiler > 0) return null;

    final role = vns
        .where((v) => ((v['spoiler'] as num?)?.toInt() ?? 0) == 0)
        .map((v) => CharacterRole.fromApi(v['role'] as String?))
        .reduce((a, b) => a.index < b.index ? a : b);

    final image = j['image'] as Map<String, dynamic>?;
    return VnCharacter(
      id: j['id'] as String,
      name: j['name'] as String,
      original: j['original'] as String?,
      description: j['description'] as String?,
      imageUrl: image?['url'] as String?,
      imageSexual: (image?['sexual'] as num?)?.toDouble() ?? 0,
      imageViolence: (image?['violence'] as num?)?.toDouble() ?? 0,
      role: role,
    );
  }
}
