import 'package:drift/drift.dart';

import '../database/database.dart';

/// Kütüphanedeki belgelere (not + PDF) erişim. UI buraya doğrudan değil,
/// Riverpod provider'ları üzerinden erişir.
class DocumentRepository {
  DocumentRepository(this._db);

  final AppDatabase _db;

  /// Çöp kutusunda OLMAYAN belgeler (kütüphane, arama, klasörler bunu kullanır).
  Stream<List<Document>> watchAll() {
    final q = _db.select(_db.documents)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);
    return q.watch();
  }

  /// Çöp kutusundaki (yumuşak silinmiş) belgeler — en son silinen en üstte.
  Stream<List<Document>> watchTrash() {
    final q = _db.select(_db.documents)
      ..where((t) => t.deletedAt.isNotNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.deletedAt, mode: OrderingMode.desc),
      ]);
    return q.watch();
  }

  /// Belgeyi çöp kutusuna taşır (yumuşak silme). Veri diskte kalır; "Son
  /// silinenler"den geri alınabilir ya da kalıcı silinebilir.
  Future<void> softDelete(int id) {
    return (_db.update(_db.documents)..where((t) => t.id.equals(id)))
        .write(DocumentsCompanion(deletedAt: Value(DateTime.now())));
  }

  /// Belgeyi çöp kutusundan geri alır (kütüphaneye döner).
  Future<void> restore(int id) {
    return (_db.update(_db.documents)..where((t) => t.id.equals(id)))
        .write(const DocumentsCompanion(deletedAt: Value(null)));
  }

  Future<Document?> getById(int id) {
    return (_db.select(_db.documents)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Tek bir belgeyi canlı dinler (canlı paylaşım senkronu için).
  Stream<Document?> watchById(int id) {
    return (_db.select(_db.documents)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }

  /// Sunucudaki paylaşımlı not kimliğine göre yerel belgeyi bulur.
  Future<Document?> getBySharedId(String sharedId) {
    return (_db.select(_db.documents)..where((t) => t.sharedId.equals(sharedId)))
        .getSingleOrNull();
  }

  /// Belgeyi paylaşımlı olarak işaretler (sunucu id + katılım kodu).
  Future<void> setShared({
    required int id,
    required String sharedId,
    required String shareCode,
  }) {
    return (_db.update(_db.documents)..where((t) => t.id.equals(id))).write(
      DocumentsCompanion(
        sharedId: Value(sharedId),
        shareCode: Value(shareCode),
      ),
    );
  }

  /// Paylaşımı yereldeki nottan kaldırır (kişisel nota döner). Çizimler kalır.
  Future<void> clearShared(int id) {
    return (_db.update(_db.documents)..where((t) => t.id.equals(id))).write(
      const DocumentsCompanion(
        sharedId: Value(null),
        shareCode: Value(null),
      ),
    );
  }

  /// Uzaktan gelen not içeriğini yerel belgeye uygular (canlı paylaşım).
  Future<void> applyRemote({
    required int id,
    required String title,
    required String body,
    required String pageColor,
    required int pageCount,
  }) {
    return (_db.update(_db.documents)..where((t) => t.id.equals(id))).write(
      DocumentsCompanion(
        title: Value(title),
        body: Value(body),
        pageColor: Value(pageColor),
        pageCount: Value(pageCount),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> insertNote({
    required String title,
    String body = '',
    String folder = 'Kişisel',
    String pageSize = 'serbest',
    String pageColor = 'beyaz',
    String pageBackground = 'duz',
    int? pageCount,
  }) {
    final now = DateTime.now();
    return _db.into(_db.documents).insert(
          DocumentsCompanion.insert(
            type: 'not',
            title: Value(title),
            body: Value(body),
            folder: Value(folder),
            pageSize: Value(pageSize),
            pageColor: Value(pageColor),
            pageBackground: Value(pageBackground),
            pageCount: Value(pageCount),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  /// Notun sayfa arka planını (kâğıt deseni) günceller.
  Future<void> setPageBackground({required int id, required String value}) {
    return (_db.update(_db.documents)..where((t) => t.id.equals(id))).write(
      DocumentsCompanion(
        pageBackground: Value(value),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Not defterine sayfa sayısını günceller (yeni sayfa eklerken).
  Future<void> setPageCount({required int id, required int pageCount}) {
    return (_db.update(_db.documents)..where((t) => t.id.equals(id)))
        .write(DocumentsCompanion(pageCount: Value(pageCount)));
  }

  /// Notun kağıt (sayfa) rengini günceller.
  Future<void> setPageColor({required int id, required String pageColor}) {
    return (_db.update(_db.documents)..where((t) => t.id.equals(id))).write(
      DocumentsCompanion(
        pageColor: Value(pageColor),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> insertPdf({
    required String title,
    required String filePath,
    required int pageCount,
    String folder = 'Kişisel',
  }) {
    final now = DateTime.now();
    return _db.into(_db.documents).insert(
          DocumentsCompanion.insert(
            type: 'pdf',
            title: Value(title),
            folder: Value(folder),
            filePath: Value(filePath),
            pageCount: Value(pageCount),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> updateNote({
    required int id,
    required String title,
    required String body,
  }) {
    return (_db.update(_db.documents)..where((t) => t.id.equals(id))).write(
      DocumentsCompanion(
        title: Value(title),
        body: Value(body),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Bir klasördeki tüm belgeleri başka klasöre taşır (klasör silinirken).
  Future<void> reassignFolder({required String from, required String to}) {
    return (_db.update(_db.documents)..where((t) => t.folder.equals(from)))
        .write(DocumentsCompanion(folder: Value(to)));
  }

  Future<void> updateFolder({required int id, required String folder}) {
    return (_db.update(_db.documents)..where((t) => t.id.equals(id))).write(
      DocumentsCompanion(
        folder: Value(folder),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Belgeyi kütüphanede sabitler / sabitlemeyi kaldırır. Sabitleme "son
  /// düzenleme" zamanını DEĞİŞTİRMEZ (tarih sıralaması bozulmasın diye).
  Future<void> setPinned({required int id, required bool pinned}) {
    return (_db.update(_db.documents)..where((t) => t.id.equals(id)))
        .write(DocumentsCompanion(pinned: Value(pinned)));
  }

  /// Bir belgeyi son düzenleme zamanına taşır (açıldığında/çizildiğinde).
  Future<void> touch(int id) {
    return (_db.update(_db.documents)..where((t) => t.id.equals(id))).write(
      DocumentsCompanion(updatedAt: Value(DateTime.now())),
    );
  }

  Future<void> delete(int id) {
    return (_db.delete(_db.documents)..where((t) => t.id.equals(id))).go();
  }

  /// Örnek not tohumlaması KALDIRILDI — uygulama ilk açılışta boş başlar.
  /// (Geriye dönük uyumluluk için imza korunuyor; artık çağrılmıyor.)
  Future<void> seedIfEmpty() async {}
}
