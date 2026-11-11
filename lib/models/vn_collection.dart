/// One of your own collections, e.g. "Favorites" or "Recommend to friends".
/// A VN can be in any number of collections, as long as it's in one of
/// your four lists.
class VnCollection {
  const VnCollection({
    required this.key,
    required this.name,
    required this.vnIds,
    required this.order,
  });

  final int key; // database key
  final String name;
  final List<String> vnIds;
  final int order; // position among the collection tabs

  int get count => vnIds.length;

  factory VnCollection.fromDb(int key, Map<String, Object?> row) => VnCollection(
        key: key,
        name: (row['name'] as String?) ?? 'Untitled',
        vnIds: [
          for (final id in (row['vn_ids'] as List<Object?>?) ?? const [])
            if (id is String) id,
        ],
        order: (row['order'] as num?)?.toInt() ?? 0,
      );
}
