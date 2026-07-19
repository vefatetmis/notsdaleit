import 'package:drift/drift.dart';

import '../database/database.dart';

/// Kalıcı klasörler (boş klasör de yaşasın diye ayrı tabloda). Kütüphanedeki
/// klasör listesi = bu tablo ∪ belgelerin `folder` alanları.
class FolderRepository {
  FolderRepository(this._db);

  final AppDatabase _db;

  Stream<List<Folder>> watchAll() {
    final q = _db.select(_db.folders)
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]);
    return q.watch();
  }

  /// Klasör ekler (aynı ad varsa yok sayar).
  Future<void> add(String name) async {
    final n = name.trim();
    if (n.isEmpty) return;
    await _db.into(_db.folders).insert(
          FoldersCompanion.insert(name: n, createdAt: DateTime.now()),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> deleteByName(String name) =>
      (_db.delete(_db.folders)..where((t) => t.name.equals(name))).go();
}
