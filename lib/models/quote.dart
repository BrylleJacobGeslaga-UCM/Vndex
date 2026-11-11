/// A memorable line from a VN, voted on by VNDB users.
class VnQuote {
  const VnQuote({
    required this.id,
    required this.text,
    required this.score,
    this.characterName,
    this.characterOriginal,
    this.imageUrl,
    this.imageSensitive = false,
    this.spoilerCharacter = false,
  });

  final String id;
  final String text;
  final int score;

  /// Who said it (null if VNDB doesn't link a character).
  final String? characterName;
  final String? characterOriginal;
  final String? imageUrl;
  final bool imageSensitive;

  /// The speaker is a spoiler in this VN, so the quote is hidden until tapped.
  final bool spoilerCharacter;

  factory VnQuote.fromJson(Map<String, dynamic> j, String vnId) {
    final c = j['character'] as Map<String, dynamic>?;
    final image = c?['image'] as Map<String, dynamic>?;

    // Speaker counts as a spoiler if every listing of them in this VN is one.
    final links = [
      for (final v in (c?['vns'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>())
        if (v['id'] == vnId) (v['spoiler'] as num?)?.toInt() ?? 0,
    ];
    final spoiler = links.isNotEmpty && links.reduce((a, b) => a < b ? a : b) > 0;

    return VnQuote(
      id: j['id'] as String,
      text: (j['quote'] as String).trim(),
      score: (j['score'] as num?)?.toInt() ?? 0,
      characterName: c?['name'] as String?,
      characterOriginal: c?['original'] as String?,
      imageUrl: image?['url'] as String?,
      imageSensitive: ((image?['sexual'] as num?) ?? 0) >= 1 ||
          ((image?['violence'] as num?) ?? 0) >= 1,
      spoilerCharacter: spoiler,
    );
  }
}
