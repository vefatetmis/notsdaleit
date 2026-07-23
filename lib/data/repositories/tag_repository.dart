import 'package:drift/drift.dart';

import '../database/database.dart';

/// Kalıcı etiketler (#önemli, #sınav…) ve belge-etiket bağları. Etiketler
/// çoklu-çoğa: bir belgede birden çok etiket, bir etikette birden çok belge.
class TagRepository {
  TagRepository(this._db);

  final AppDatabase _db;

  /// Tüm etiketler (ada göre sıralı) — canlı akış.
  Stream<List<Tag>> watchAll() {
    final q = _db.select(_db.tags)
      ..orderBy([(t) => OrderingTerm(expression: t.name)]);
    return q.watch();
  }

  /// Tüm belge-etiket bağları — canlı akış (sayım + filtreleme için).
  Stream<List<DocumentTag>> watchLinks() => _db.select(_db.documentTags).watch();

  /// Etiketi bulur; yoksa oluşturur. Her iki durumda da id döner.
  Future<int> ensureTag(String name) async {
    final n = name.trim();
    if (n.isEmpty) return -1;
    final existing =
        await (_db.select(_db.tags)..where((t) => t.name.equals(n)))
            .getSingleOrNull();
    if (existing != null) return existing.id;
    return _db.into(_db.tags).insert(
          TagsCompanion.insert(name: n, createdAt: DateTime.now()),
        );
  }

  /// Etiketi siler (bağları cascade ile kalkar).
  Future<void> deleteTag(int id) =>
      (_db.delete(_db.tags)..where((t) => t.id.equals(id))).go();

  /// Etiketi yeniden adlandırır (aynı ada çakışırsa çağıran engellemeli).
  Future<void> rename(int id, String name) {
    final n = name.trim();
    if (n.isEmpty) return Future.value();
    return (_db.update(_db.tags)..where((t) => t.id.equals(id)))
        .write(TagsCompanion(name: Value(n)));
  }

  Future<void> addLink(int docId, int tagId) =>
      _db.into(_db.documentTags).insert(
            DocumentTagsCompanion.insert(docId: docId, tagId: tagId),
            mode: InsertMode.insertOrIgnore,
          );

  Future<void> removeLink(int docId, int tagId) =>
      (_db.delete(_db.documentTags)
            ..where((t) => t.docId.equals(docId) & t.tagId.equals(tagId)))
          .go();

  /// Bir etiketi seçili belgelerin hepsine ekler ([add] true) ya da hepsinden
  /// kaldırır ([add] false).
  Future<void> setLinkForDocs(Set<int> docIds, int tagId, bool add) async {
    for (final d in docIds) {
      if (add) {
        await addLink(d, tagId);
      } else {
        await removeLink(d, tagId);
      }
    }
  }
}
