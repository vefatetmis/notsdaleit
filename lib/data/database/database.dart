import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// Kütüphanedeki her öğe (not veya PDF) bu tabloda tutulur.
/// [type] 'not' ya da 'pdf' olur. Notlarda [body], PDF'lerde [filePath] +
/// [pageCount] dolu olur.
class Documents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text().withLength(min: 1, max: 8)();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get folder => text().withDefault(const Constant('Kişisel'))();
  TextColumn get body => text().withDefault(const Constant(''))();
  TextColumn get filePath => text().nullable()();
  IntColumn get pageCount => integer().nullable()();
  // Not sayfa biçimi: 'serbest' (akışkan metin), 'a4' veya 'kare' (sabit sayfa).
  TextColumn get pageSize => text().withDefault(const Constant('serbest'))();
  // Kağıt (sayfa) rengi: 'beyaz' | 'sari' | 'yesil' | 'siyah'.
  TextColumn get pageColor => text().withDefault(const Constant('beyaz'))();
  // Sayfa arka planı (kâğıt deseni): 'duz' | 'cizgili' | 'kareli' | 'noktali'.
  TextColumn get pageBackground =>
      text().withDefault(const Constant('duz'))();
  // Canlı ortak not: Supabase'teki shared_notes.id (uuid). Dolu ise bu not
  // paylaşımlıdır ve açıkken gerçek zamanlı eşitlenir.
  TextColumn get sharedId => text().nullable()();
  // Paylaşım katılım kodu (örn. 'K7M2PX') — sahibi başkalarını davet ederken
  // gösterir.
  TextColumn get shareCode => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Bir belgenin (not/PDF) üzerine yapılan kalem çizimleri. Nokta koordinatları
/// 0..1 aralığında normalize edilmiş JSON olarak saklanır; böylece yakınlaştırma
/// ve ekran boyutundan bağımsız çalışır.
class Strokes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get docId =>
      integer().references(Documents, #id, onDelete: KeyAction.cascade)();
  IntColumn get page => integer().withDefault(const Constant(0))();
  TextColumn get tool => text()(); // 'kalem' | 'fosfor' | 'silgi'
  IntColumn get color => integer().withDefault(const Constant(0xFF262626))();
  RealColumn get width => real().withDefault(const Constant(5))();
  TextColumn get points => text()(); // JSON: [[x,y],...] (0..1)
  // Canlı ortak notta bu çizginin sunucudaki uuid'si (yankı/çift kaydı önler:
  // uzaktan gelen olay zaten bizdeyse yok sayılır).
  TextColumn get remoteId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Yapılacaklar / takvim görevleri. [dueDate] verilirse o güne düşer;
/// [remindAt] ileride bildirim için kullanılacaktır.
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get remindAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Bir güne ait serbest not (takvimde gün seçince alttan yazılır).
class DayNotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get day => dateTime()(); // gün (00:00)
  TextColumn get body => text().withDefault(const Constant(''))();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Tekrarlayan rutinler (alışkanlık takibi). [days] Pzt..Paz için '1'/'0'
/// içeren 7 karakterlik maske ('1111111' = her gün, '0010000' = her çarşamba).
class Routines extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get days => text().withDefault(const Constant('1111111'))();
  // Bildirim saati: gece yarısından itibaren dakika (0..1439). Null ise
  // hatırlatıcı yok. Seçili her gün için o saatte bildirim planlanır.
  IntColumn get remindAt => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Kalıcı klasörler. Belgelerin `folder` alanından türeyen klasörlere ek
/// olarak, kullanıcının oluşturduğu (henüz belgesi olmayan) boş klasörler de
/// yaşasın diye ayrı tabloda tutulur.
class Folders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Kullanıcının kaydettiği not şablonları ("Şablonlarım"). Gömülü hazır
/// şablonlar koda gömülüdür; bu tablo yalnızca kullanıcının "Şablon olarak
/// kaydet" ile oluşturduklarını tutar. Model .ntdl ile aynıdır: metin gövdesi
/// (Quill Delta JSON) + sayfa boyutu/rengi + çizimler (JSON dizisi).
class Templates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get pageSize => text().withDefault(const Constant('a4'))();
  TextColumn get pageColor => text().withDefault(const Constant('beyaz'))();
  TextColumn get pageBackground =>
      text().withDefault(const Constant('duz'))();
  TextColumn get body => text().withDefault(const Constant(''))();
  // Çizimler: [{page,tool,color,width,points}, ...] JSON dizisi (0..1 normalize).
  TextColumn get strokes => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime()();
}

/// Bir rutinin belirli bir günde tamamlandığının kaydı. Satır varsa o gün
/// yapılmış demektir; işaret kaldırılınca satır silinir.
class RoutineChecks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get routineId =>
      integer().references(Routines, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get day => dateTime()(); // gün (00:00)
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(tables: [
  Documents,
  Strokes,
  Tasks,
  DayNotes,
  Routines,
  RoutineChecks,
  Folders,
  Templates,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(documents, documents.pageSize);
          }
          if (from < 3) {
            await m.createTable(tasks);
          }
          if (from < 4) {
            await m.createTable(dayNotes);
          }
          if (from < 5) {
            await m.addColumn(documents, documents.pageColor);
          }
          if (from < 6) {
            await m.createTable(routines);
            await m.createTable(routineChecks);
          }
          if (from < 7) {
            await m.addColumn(documents, documents.sharedId);
            await m.addColumn(documents, documents.shareCode);
            await m.addColumn(strokes, strokes.remoteId);
          }
          if (from < 8) {
            await m.addColumn(routines, routines.remindAt);
            await m.createTable(folders);
          }
          if (from < 9) {
            await m.createTable(templates);
          }
          if (from < 10) {
            await m.addColumn(documents, documents.pageBackground);
            await m.addColumn(templates, templates.pageBackground);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'notdaleit_db');
  }
}
