import 'package:drift/drift.dart';

import '../database/database.dart';

/// Belgeler üzerindeki kalem çizimlerine erişim.
class DrawingRepository {
  DrawingRepository(this._db);

  final AppDatabase _db;

  /// Bir belgenin tüm çizimlerini (tüm sayfalar) çizim sırasına göre dinler.
  Stream<List<Stroke>> watchStrokes(int docId) {
    final q = _db.select(_db.strokes)
      ..where((t) => t.docId.equals(docId))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]);
    return q.watch();
  }

  /// Bir belgenin tüm çizimlerini tek seferde döndürür (PDF dışa aktarma için).
  Future<List<Stroke>> getStrokes(int docId) {
    final q = _db.select(_db.strokes)
      ..where((t) => t.docId.equals(docId))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]);
    return q.get();
  }

  Future<void> addStroke({
    required int docId,
    required int page,
    required String tool,
    required int color,
    required double width,
    required String pointsJson,
    String? remoteId,
  }) {
    return _db.into(_db.strokes).insert(
          StrokesCompanion.insert(
            docId: docId,
            page: Value(page),
            tool: tool,
            color: Value(color),
            width: Value(width),
            points: pointsJson,
            remoteId: Value(remoteId),
            createdAt: DateTime.now(),
          ),
        );
  }

  /// Bir çizginin noktalarını değiştirir (lasso ile taşıma). NOT: canlı
  /// paylaşımda taşıma sunucuya gönderilmez (collab yalnızca ekleme/silme
  /// olaylarını taşır) — karşı tarafta çizgi eski yerinde kalır.
  Future<void> updateStrokePoints(int id, String pointsJson) {
    return (_db.update(_db.strokes)..where((t) => t.id.equals(id)))
        .write(StrokesCompanion(points: Value(pointsJson)));
  }

  /// Seçili çizgileri siler (lasso seçimi).
  Future<void> deleteStrokes(Set<int> ids) async {
    for (final id in ids) {
      await (_db.delete(_db.strokes)..where((t) => t.id.equals(id))).go();
    }
  }

  /// Yerel çizgiye sunucudaki uuid'sini yazar (canlı paylaşım).
  Future<void> setStrokeRemoteId(int id, String remoteId) {
    return (_db.update(_db.strokes)..where((t) => t.id.equals(id)))
        .write(StrokesCompanion(remoteId: Value(remoteId)));
  }

  /// Sunucu uuid'sine göre yerel çizgiyi siler (uzaktan silme olayı).
  Future<void> deleteByRemoteId(int docId, String remoteId) {
    return (_db.delete(_db.strokes)
          ..where((t) => t.docId.equals(docId) & t.remoteId.equals(remoteId)))
        .go();
  }

  /// Sayfadaki son çizimi geri alır.
  Future<void> undoLast({required int docId, required int page}) async {
    final last = await (_db.select(_db.strokes)
          ..where((t) => t.docId.equals(docId) & t.page.equals(page))
          ..orderBy([
            (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
    if (last != null) {
      await (_db.delete(_db.strokes)..where((t) => t.id.equals(last.id))).go();
    }
  }

  Future<void> clear({required int docId, required int page}) {
    return (_db.delete(_db.strokes)
          ..where((t) => t.docId.equals(docId) & t.page.equals(page)))
        .go();
  }

  /// Belgedeki (tüm sayfalar) en son çizimi geri alır ve silinen satırı
  /// döndürür — "ileri al" bu satırı geri koyabilsin diye.
  Future<Stroke?> undoLastForDoc(int docId) async {
    final last = await (_db.select(_db.strokes)
          ..where((t) => t.docId.equals(docId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
    if (last == null) return null;
    await (_db.delete(_db.strokes)..where((t) => t.id.equals(last.id))).go();
    return last;
  }

  /// Geri alınan bir çizimi geri koyar ("ileri al"). Yeni bir satır olarak
  /// eklenir; `remoteId` taşınmaz, böylece canlı paylaşımda yeniden gönderilir.
  Future<void> restoreStroke(Stroke s) {
    return addStroke(
      docId: s.docId,
      page: s.page,
      tool: s.tool,
      color: s.color,
      width: s.width,
      pointsJson: s.points,
    );
  }

  /// Belgedeki tüm çizimleri siler.
  Future<void> clearDoc(int docId) {
    return (_db.delete(_db.strokes)..where((t) => t.docId.equals(docId))).go();
  }
}
