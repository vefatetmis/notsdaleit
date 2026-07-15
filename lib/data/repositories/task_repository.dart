import 'package:drift/drift.dart';

import '../database/database.dart';

/// Yapılacaklar / takvim görevlerine erişim.
class TaskRepository {
  TaskRepository(this._db);

  final AppDatabase _db;

  /// Tüm görevleri canlı dinler (tarihe, sonra oluşturulma zamanına göre).
  Stream<List<Task>> watchAll() {
    final q = _db.select(_db.tasks)
      ..orderBy([
        (t) => OrderingTerm(expression: t.dueDate),
        (t) => OrderingTerm(expression: t.createdAt),
      ]);
    return q.watch();
  }

  Future<int> insert({
    required String title,
    DateTime? dueDate,
    DateTime? remindAt,
  }) {
    return _db.into(_db.tasks).insert(
          TasksCompanion.insert(
            title: title,
            dueDate: Value(dueDate),
            remindAt: Value(remindAt),
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<void> setDone({required int id, required bool done}) {
    return (_db.update(_db.tasks)..where((t) => t.id.equals(id)))
        .write(TasksCompanion(done: Value(done)));
  }

  Future<void> update({
    required int id,
    required String title,
    DateTime? dueDate,
    DateTime? remindAt,
  }) {
    return (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        title: Value(title),
        dueDate: Value(dueDate),
        remindAt: Value(remindAt),
      ),
    );
  }

  Future<void> delete(int id) {
    return (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();
  }
}
