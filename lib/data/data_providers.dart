import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/shell/shell_state.dart';
import 'database/database.dart';
import 'repositories/day_note_repository.dart';
import 'repositories/document_repository.dart';
import 'repositories/drawing_repository.dart';
import 'repositories/folder_repository.dart';
import 'repositories/routine_repository.dart';
import 'repositories/task_repository.dart';

/// Uygulama boyunca açık kalan tek veritabanı.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository(ref.watch(databaseProvider));
});

final drawingRepositoryProvider = Provider<DrawingRepository>((ref) {
  return DrawingRepository(ref.watch(databaseProvider));
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(databaseProvider));
});

/// Tüm görevler — canlı akış.
final tasksProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(taskRepositoryProvider).watchAll();
});

final dayNoteRepositoryProvider = Provider<DayNoteRepository>((ref) {
  return DayNoteRepository(ref.watch(databaseProvider));
});

final folderRepositoryProvider = Provider<FolderRepository>((ref) {
  return FolderRepository(ref.watch(databaseProvider));
});

/// Kalıcı klasörler — canlı akış.
final foldersProvider = StreamProvider<List<Folder>>((ref) {
  return ref.watch(folderRepositoryProvider).watchAll();
});

final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  return RoutineRepository(ref.watch(databaseProvider));
});

/// Tüm rutinler — canlı akış.
final routinesProvider = StreamProvider<List<Routine>>((ref) {
  return ref.watch(routineRepositoryProvider).watchAll();
});

/// Tüm rutin tamamlama kayıtları — canlı akış.
final routineChecksProvider = StreamProvider<List<RoutineCheck>>((ref) {
  return ref.watch(routineRepositoryProvider).watchChecks();
});

/// Tüm gün notları — canlı akış.
final dayNotesProvider = StreamProvider<List<DayNote>>((ref) {
  return ref.watch(dayNoteRepositoryProvider).watchAll();
});

/// Tüm belgeler (not + PDF), en son güncellenen en üstte. Canlı akış.
final documentsProvider = StreamProvider<List<Document>>((ref) {
  return ref.watch(documentRepositoryProvider).watchAll();
});

/// Şu an açık olan belge (editör/PDF ekranı için).
final activeDocumentProvider = Provider<Document?>((ref) {
  final id = ref.watch(navProvider).activeDocId;
  if (id == null) return null;
  final docs = ref.watch(documentsProvider).valueOrNull;
  if (docs == null) return null;
  for (final d in docs) {
    if (d.id == id) return d;
  }
  return null;
});

/// Klasör adları: varsayılanlar ∪ kalıcı klasörler (Folders tablosu) ∪
/// belgelerin kullandığı klasörler ∪ oturumluk ekstralar.
final folderNamesProvider = Provider<List<String>>((ref) {
  final docs = ref.watch(documentsProvider).valueOrNull ?? const [];
  final persistent = ref.watch(foldersProvider).valueOrNull ?? const [];
  final extras = ref.watch(extraFoldersProvider);
  final result = <String>['Ders Notları', 'İş', 'Kişisel'];
  for (final f in persistent) {
    if (!result.contains(f.name)) result.add(f.name);
  }
  for (final d in docs) {
    if (!result.contains(d.folder)) result.add(d.folder);
  }
  for (final e in extras) {
    if (!result.contains(e)) result.add(e);
  }
  return result;
});
