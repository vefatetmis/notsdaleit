import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';

import 'database/database.dart';

/// EKRAN GÖRÜNTÜSÜ DEMOSU — mağaza görselleri için gerçekçi örnek içerik.
///
/// Yalnızca veritabanı BOŞKEN çalışır (gerçek veriye asla dokunmaz).
/// main.dart'taki `kSeedDemoContent` bayrağıyla, ayrı paket adlı geçici
/// derlemelerde kullanılır (bkz. CLAUDE.md "Ekran görüntüsü demosu").
Future<void> seedDemoContent(AppDatabase db) async {
  final count = await db.documents.count().getSingle();
  if (count > 0) return;

  final now = DateTime.now();
  DateTime ago({int days = 0, int hours = 0}) =>
      now.subtract(Duration(days: days, hours: hours));

  // ── Notlar ──────────────────────────────────────────────

  Future<int> note({
    required String title,
    required String folder,
    required List<Map<String, dynamic>> delta,
    required DateTime when,
    String pageColor = 'beyaz',
    String pageSize = 'a4',
  }) {
    return db.into(db.documents).insert(DocumentsCompanion.insert(
          type: 'not',
          title: Value(title),
          folder: Value(folder),
          body: Value(jsonEncode(delta)),
          pageSize: Value(pageSize),
          pageColor: Value(pageColor),
          pageCount: const Value(1),
          createdAt: when,
          updatedAt: when,
        ));
  }

  Map<String, dynamic> t(String s, [Map<String, dynamic>? a]) =>
      {'insert': s, if (a != null) 'attributes': a};
  Map<String, dynamic> nl([Map<String, dynamic>? a]) =>
      {'insert': '\n', if (a != null) 'attributes': a};

  final bioId = await note(
    title: 'Biyoloji — Hücre Bölünmesi',
    folder: 'Ders Notları',
    when: ago(hours: 2),
    delta: [
      t('Mitoz Evreleri', {'bold': true}),
      nl(),
      t('Profaz — kromozomlar belirginleşir'),
      nl({'list': 'bullet'}),
      t('Metafaz — ekvatoral dizilim'),
      nl({'list': 'bullet'}),
      t('Anafaz — kutuplara çekilme'),
      nl({'list': 'bullet'}),
      t('Telofaz — iki yeni çekirdek'),
      nl({'list': 'bullet'}),
      t('Sınavda şema çizimi isteniyor!'),
      nl(),
    ],
  );

  final nightId = await note(
    title: 'Gece Çalışma Notları',
    folder: 'Ders Notları',
    when: ago(hours: 5),
    pageColor: 'siyah',
    delta: [
      t('Yarın: türev tekrarı', {'bold': true}),
      nl(),
      t('Formül kartları hazır'),
      nl({'list': 'checked'}),
      t('Uyumadan 20 sayfa kitap'),
      nl({'list': 'unchecked'}),
    ],
  );

  await note(
    title: 'Haftalık Plan',
    folder: 'Kişisel',
    when: ago(days: 1, hours: 3),
    pageSize: 'kare',
    delta: [
      t('Sunum hazırla'),
      nl({'list': 'checked'}),
      t('Spor salonu'),
      nl({'list': 'checked'}),
      t('Kitap: 50 sayfa'),
      nl({'list': 'unchecked'}),
      t('Anneme uğra'),
      nl({'list': 'unchecked'}),
    ],
  );

  await note(
    title: 'Toplantı Notları — Pazartesi',
    folder: 'İş',
    when: ago(days: 2, hours: 1),
    delta: [
      t('Katılımcılar: Elif, Mert, Deniz'),
      nl(),
      t('Tasarım teslimi cuma günü'),
      nl({'list': 'bullet'}),
      t('Logo seçenekleri salıya hazır'),
      nl({'list': 'bullet'}),
      t('Önemli: ', {'bold': true}),
      t('bütçe revizesi perşembe'),
      nl(),
    ],
  );

  await note(
    title: 'Alışveriş Listesi',
    folder: 'Kişisel',
    when: ago(days: 4, hours: 6),
    delta: [
      t('Süt, yumurta'),
      nl({'list': 'bullet'}),
      t('Filtre kahve'),
      nl({'list': 'bullet'}),
      t('A5 çizim defteri'),
      nl({'list': 'bullet'}),
    ],
  );

  await note(
    title: 'Fikirler 💡',
    folder: 'Kişisel',
    when: ago(days: 7, hours: 2),
    delta: [
      t('Sesli notu metne çevirme'),
      nl({'list': 'bullet'}),
      t('Haftalık plan şablonu paylaş'),
      nl({'list': 'bullet'}),
      t('Balkon bahçesi günlüğü'),
      nl({'list': 'bullet'}),
    ],
  );

  // Kütüphanede PDF kartı görünsün diye (açılmaz — dosya yok). Tarihi taze
  // tutulur ki listede üst sıralarda, ilk ekranda görünsün.
  await db.into(db.documents).insert(DocumentsCompanion.insert(
        type: 'pdf',
        title: const Value('Fizik Ders Notları'),
        folder: const Value('Ders Notları'),
        filePath: const Value('/demo/fizik.pdf'),
        pageCount: const Value(12),
        createdAt: ago(hours: 3),
        updatedAt: ago(hours: 3),
      ));

  // ── Çizimler (normalize: her iki eksen ÷ genişlik) ──────

  Future<void> stroke(int docId, List<List<double>> pts,
      {String tool = 'kalem', int color = 0xFF4A6CF7, double width = 5}) {
    return db.into(db.strokes).insert(StrokesCompanion.insert(
          docId: docId,
          page: const Value(0),
          tool: tool,
          color: Value(color),
          width: Value(width),
          points: jsonEncode([
            for (final p in pts)
              [
                double.parse(p[0].toStringAsFixed(4)),
                double.parse(p[1].toStringAsFixed(4)),
              ]
          ]),
          createdAt: DateTime.now(),
        ));
  }

  // Elle çizilmiş hissi için hafif titrek daire.
  List<List<double>> circle(double cx, double cy, double r,
      {double from = 0, double to = 2 * math.pi}) {
    final pts = <List<double>>[];
    const steps = 36;
    for (var i = 0; i <= steps; i++) {
      final a = from + (to - from) * i / steps;
      final jit = 1 + 0.035 * math.sin(a * 3 + cx * 10);
      pts.add([cx + r * jit * math.cos(a), cy + r * jit * math.sin(a)]);
    }
    return pts;
  }

  List<List<double>> line(double x1, double y1, double x2, double y2) {
    final pts = <List<double>>[];
    const steps = 14;
    for (var i = 0; i <= steps; i++) {
      final f = i / steps;
      final jit = 0.004 * math.sin(f * math.pi * 2.7);
      pts.add([x1 + (x2 - x1) * f, y1 + (y2 - y1) * f + jit]);
    }
    return pts;
  }

  // Biyoloji notu: başlık altı kırmızı çizgi + fosforlu vurgu + hücre şeması.
  const blue = 0xFF4A6CF7, red = 0xFFE0533D, yellow = 0xFFF0B429;
  await stroke(bioId, line(0.06, 0.098, 0.38, 0.104), color: red, width: 2.5);
  await stroke(bioId, line(0.055, 0.155, 0.55, 0.158),
      tool: 'fosfor', color: yellow, width: 9);
  // ana hücre + çekirdek
  await stroke(bioId, circle(0.28, 0.78, 0.13), color: blue);
  await stroke(bioId, circle(0.28, 0.78, 0.05), color: blue, width: 2.5);
  // ok
  await stroke(bioId, line(0.44, 0.78, 0.58, 0.78), color: red, width: 2.5);
  await stroke(bioId, line(0.545, 0.755, 0.58, 0.78), color: red, width: 2.5);
  await stroke(bioId, line(0.545, 0.805, 0.58, 0.78), color: red, width: 2.5);
  // bölünen hücre + orta çizgi + iki çekirdek
  await stroke(bioId, circle(0.76, 0.78, 0.13), color: blue);
  await stroke(bioId, line(0.76, 0.655, 0.76, 0.905), color: blue, width: 2.5);
  await stroke(bioId, circle(0.70, 0.78, 0.035), color: blue, width: 2.5);
  await stroke(bioId, circle(0.82, 0.78, 0.035), color: blue, width: 2.5);

  // Gece notu (siyah kağıt): beyaz hilal + yıldızlar.
  const white = 0xFFFFFFFF;
  await stroke(nightId, circle(0.5, 0.75, 0.12, from: -1.3, to: 1.9),
      color: white);
  await stroke(nightId, circle(0.56, 0.73, 0.1, from: -1.1, to: 1.7),
      color: white, width: 2.5);
  for (final s in [
    [0.26, 0.58],
    [0.74, 0.55],
    [0.63, 0.95],
  ]) {
    await stroke(nightId, line(s[0] - 0.02, s[1], s[0] + 0.02, s[1]),
        color: white, width: 2.5);
    await stroke(nightId, line(s[0], s[1] - 0.02, s[0], s[1] + 0.02),
        color: white, width: 2.5);
  }

  // ── Takvim: bugünün görevleri + gün notu ─────────────────

  final today = DateTime(now.year, now.month, now.day);
  Future<void> task(String title,
      {bool done = false, DateTime? remindAt}) {
    return db.into(db.tasks).insert(TasksCompanion.insert(
          title: title,
          done: Value(done),
          dueDate: Value(today),
          remindAt: Value(remindAt),
          createdAt: now,
        )).then((_) {});
  }

  await task('Proje teslimi');
  await task('Diş hekimi',
      remindAt: DateTime(now.year, now.month, now.day, 14, 30));
  await task('Market alışverişi', done: true);

  await db.into(db.dayNotes).insert(DayNotesCompanion.insert(
        day: today,
        body: const Value('Sabah koşusu iyi geçti. Öğleden sonra kütüphane.'),
        updatedAt: now,
      ));

  // ── Rutinler + ~3 haftalık gerçekçi geçmiş ───────────────

  Future<int> routine(String title, String days) =>
      db.into(db.routines).insert(RoutinesCompanion.insert(
            title: title,
            days: Value(days),
            createdAt: ago(days: 24),
          ));

  bool scheduled(String mask, DateTime d) => mask[d.weekday - 1] == '1';

  Future<void> check(int routineId, DateTime day) =>
      db.into(db.routineChecks).insert(RoutineChecksCompanion.insert(
            routineId: routineId,
            day: DateTime(day.year, day.month, day.day),
            createdAt: now,
          )).then((_) {});

  final water = await routine('2 litre su iç', '1111111');
  final book = await routine('30 dk kitap oku', '1111111');
  final sport = await routine('Spor', '1010100'); // Pzt, Çar, Cum
  final english = await routine('İngilizce kelime tekrarı', '1111111');

  for (var i = 0; i <= 23; i++) {
    final d = today.subtract(Duration(days: i));
    if (i % 5 != 3) await check(water, d); // ~%80
    if (i % 3 != 1 && i != 0) await check(book, d); // bugün boş kalsın
    if (scheduled('1010100', d) && i % 4 != 2) await check(sport, d);
    if (i % 2 == 0 && i != 0) await check(english, d); // bugün boş
  }
}
