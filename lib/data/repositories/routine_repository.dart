import 'package:drift/drift.dart';

import '../database/database.dart';

/// Rutinler (alışkanlık takibi): tanımlar + günlük tamamlama işaretleri.
class RoutineRepository {
  RoutineRepository(this._db);

  final AppDatabase _db;

  Stream<List<Routine>> watchAll() {
    final q = _db.select(_db.routines)
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]);
    return q.watch();
  }

  /// Tüm tamamlama kayıtları — canlı akış (veri hacmi küçük; UI hem bugünkü
  /// durumu hem geçmiş görünümünü bundan türetir).
  Stream<List<RoutineCheck>> watchChecks() =>
      _db.select(_db.routineChecks).watch();

  Future<int> insert({required String title, required String days}) {
    return _db.into(_db.routines).insert(RoutinesCompanion.insert(
          title: title,
          days: Value(days),
          createdAt: DateTime.now(),
        ));
  }

  Future<void> delete(int id) =>
      (_db.delete(_db.routines)..where((t) => t.id.equals(id))).go();

  /// Rutinin bildirim saatini ayarlar: [minutes] gece yarısından dakika, null
  /// ise hatırlatıcıyı kaldırır.
  Future<void> setRemindAt({required int id, required int? minutes}) {
    return (_db.update(_db.routines)..where((t) => t.id.equals(id)))
        .write(RoutinesCompanion(remindAt: Value(minutes)));
  }

  /// Bir günün işaretini değiştirir: varsa kaldırır, yoksa ekler.
  /// [day] gün hassasiyetine indirgenir (00:00).
  Future<void> toggle({required int routineId, required DateTime day}) async {
    final d = DateTime(day.year, day.month, day.day);
    final existing = await (_db.select(_db.routineChecks)
          ..where((t) => t.routineId.equals(routineId) & t.day.equals(d)))
        .getSingleOrNull();
    if (existing != null) {
      await (_db.delete(_db.routineChecks)
            ..where((t) => t.id.equals(existing.id)))
          .go();
    } else {
      await _db.into(_db.routineChecks).insert(RoutineChecksCompanion.insert(
            routineId: routineId,
            day: d,
            createdAt: DateTime.now(),
          ));
    }
  }
}
