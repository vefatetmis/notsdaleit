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
  // Kütüphanede sabitlenmiş (pin) mi? Sabit belgeler listenin en üstünde durur.
  // Yerel bir tercihtir; canlı paylaşımda sunucuya gönderilmez.
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  // Yumuşak silme: dolu ise belge çöp kutusunda (kütüphanede/aramada görünmez).
  // null = normal. "Son silinenler"den geri alınır ya da kalıcı silinir.
  DateTimeColumn get deletedAt => dateTime().nullable()();
  // Not kilidi: true ise belge açılırken PIN sorulur ve kütüphanede içeriği
  // gizlenir. Yerel bir tercihtir (canlı paylaşımda gönderilmez).
  // NOT: bu bir ARAYÜZ kilididir, şifreleme DEĞİL — gövde veritabanında düz
  // durur (bkz. CLAUDE.md "Not kilidi").
  BoolColumn get locked => boolean().withDefault(const Constant(false))();
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

/// Kullanıcının oluşturduğu kalıcı etiketler (#önemli, #sınav…). Belgelerle
/// ilişki [DocumentTags] üzerinden (çoklu-çoğa) kurulur.
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Bir belge ↔ etiket bağı (çoklu-çoğa ara tablo). Belge ya da etiket silinince
/// bu bağ da otomatik kalkar (cascade).
class DocumentTags extends Table {
  IntColumn get docId =>
      integer().references(Documents, #id, onDelete: KeyAction.cascade)();
  IntColumn get tagId =>
      integer().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {docId, tagId};
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
  Tags,
  DocumentTags,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 14;

  /// Bir tablo veritabanında var mı?
  Future<bool> _hasTable(String name) async {
    final rows = await customSelect(
      "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?1",
      variables: [Variable<String>(name)],
    ).get();
    return rows.isNotEmpty;
  }

  /// Bir tabloda kolon var mı?
  Future<bool> _hasColumn(String table, String column) async {
    final rows = await customSelect('PRAGMA table_info("$table")').get();
    return rows.any((r) => r.read<String?>('name') == column);
  }

  /// Tabloyu **yoksa** oluşturur.
  Future<void> _createIfMissing(Migrator m, TableInfo table) async {
    if (await _hasTable(table.actualTableName)) return;
    await m.createTable(table);
  }

  /// Kolonu **yoksa** ekler.
  Future<void> _addColumnIfMissing(
      Migrator m, TableInfo table, GeneratedColumn column) async {
    if (await _hasColumn(table.actualTableName, column.name)) return;
    await m.addColumn(table, column);
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        // ── Geçişler NEDEN "varsa atla" ile yazılıyor ────────────────────
        //
        // `createTable` tabloyu **bugünkü** tanımıyla oluşturur. Yani eski bir
        // sürümden gelen kullanıcıda `from < 9` adımı `templates` tablosunu
        // `page_background` kolonu DÂHİL kuruyor, ardından `from < 10` adımı
        // aynı kolonu eklemeye çalışıp "duplicate column name" ile patlıyordu
        // (aynı tuzak `routines.remind_at` için de vardı). Sahada bu, eski
        // sürümden güncelleyen test kullanıcılarının uygulamayı hiç
        // açamamasına yol açtı.
        //
        // Bu yüzden her adım idempotent: tablo/kolon zaten varsa atlanır.
        // **Yeni geçiş yazarken de bu yardımcıları kullan.**
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await _addColumnIfMissing(m, documents, documents.pageSize);
          }
          if (from < 3) {
            await _createIfMissing(m, tasks);
          }
          if (from < 4) {
            await _createIfMissing(m, dayNotes);
          }
          if (from < 5) {
            await _addColumnIfMissing(m, documents, documents.pageColor);
          }
          if (from < 6) {
            await _createIfMissing(m, routines);
            await _createIfMissing(m, routineChecks);
          }
          if (from < 7) {
            await _addColumnIfMissing(m, documents, documents.sharedId);
            await _addColumnIfMissing(m, documents, documents.shareCode);
            await _addColumnIfMissing(m, strokes, strokes.remoteId);
          }
          if (from < 8) {
            await _addColumnIfMissing(m, routines, routines.remindAt);
            await _createIfMissing(m, folders);
          }
          if (from < 9) {
            await _createIfMissing(m, templates);
          }
          if (from < 10) {
            await _addColumnIfMissing(m, documents, documents.pageBackground);
            await _addColumnIfMissing(m, templates, templates.pageBackground);
          }
          if (from < 11) {
            await _addColumnIfMissing(m, documents, documents.pinned);
          }
          if (from < 12) {
            await _createIfMissing(m, tags);
            await _createIfMissing(m, documentTags);
          }
          if (from < 13) {
            await _addColumnIfMissing(m, documents, documents.deletedAt);
          }
          if (from < 14) {
            await _addColumnIfMissing(m, documents, documents.locked);
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
