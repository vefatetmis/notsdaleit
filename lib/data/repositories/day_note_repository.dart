import 'package:drift/drift.dart';

import '../database/database.dart';

/// Güne ait serbest notlara erişim.
class DayNoteRepository {
  DayNoteRepository(this._db);

  final AppDatabase _db;

  Stream<List<DayNote>> watchAll() => _db.select(_db.dayNotes).watch();

  /// Gün notunu kaydeder (boşsa siler).
  Future<void> setForDay(DateTime day, String body) async {
    final d = DateTime(day.year, day.month, day.day);
    final existing =
        await (_db.select(_db.dayNotes)..where((t) => t.day.equals(d)))
            .getSingleOrNull();

    if (body.trim().isEmpty) {
      if (existing != null) {
        await (_db.delete(_db.dayNotes)..where((t) => t.id.equals(existing.id)))
            .go();
      }
      return;
    }

    if (existing == null) {
      await _db.into(_db.dayNotes).insert(
            DayNotesCompanion.insert(
              day: d,
              body: Value(body),
              updatedAt: DateTime.now(),
            ),
          );
    } else {
      await (_db.update(_db.dayNotes)..where((t) => t.id.equals(existing.id)))
          .write(DayNotesCompanion(
        body: Value(body),
        updatedAt: Value(DateTime.now()),
      ));
    }
  }
}
