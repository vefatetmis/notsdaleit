import 'package:drift/drift.dart';

import '../database/database.dart';

/// Kullanıcının kaydettiği not şablonları ("Şablonlarım"). Gömülü hazır
/// şablonlar koda gömülüdür; burada yalnızca kullanıcının oluşturdukları tutulur.
class TemplateRepository {
  TemplateRepository(this._db);

  final AppDatabase _db;

  Stream<List<Template>> watchAll() {
    final q = _db.select(_db.templates)
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);
    return q.watch();
  }

  Future<int> add({
    required String title,
    required String pageSize,
    required String pageColor,
    required String body,
    String strokes = '[]',
  }) {
    return _db.into(_db.templates).insert(
          TemplatesCompanion.insert(
            title: Value(title),
            pageSize: Value(pageSize),
            pageColor: Value(pageColor),
            body: Value(body),
            strokes: Value(strokes),
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<void> delete(int id) =>
      (_db.delete(_db.templates)..where((t) => t.id.equals(id))).go();
}
