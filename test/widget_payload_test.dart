import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:notsdaleit/data/database/database.dart';
import 'package:notsdaleit/features/widget/widget_data.dart';

/// Ana ekran widget'larına giden anlık görüntü.
///
/// **Neden test ediliyor:** bu dize iki dilin sınırında duruyor — Dart üretiyor,
/// Kotlin (`WidgetStore.parse`) okuyor. Bir alan adı sessizce değişirse hiçbir
/// derleyici uyarmaz, widget yalnızca boş görünür. Ayrıca **kilitli notların
/// elenmesi** bir gizlilik kuralıdır: regresyonu kilitli notun başlığını ana
/// ekrana düşürür.
void main() {
  final now = DateTime(2026, 7, 27, 10, 0); // Pazartesi

  Document doc({
    required int id,
    String title = 'Not',
    String type = 'not',
    bool locked = false,
    String body = '',
    DateTime? updatedAt,
  }) {
    return Document(
      id: id,
      type: type,
      title: title,
      folder: 'Kişisel',
      body: body,
      pageSize: 'a4',
      pageColor: 'beyaz',
      pageBackground: 'duz',
      pinned: false,
      locked: locked,
      createdAt: now,
      updatedAt: updatedAt ?? now,
    );
  }

  Routine routine({
    required int id,
    String title = 'Su iç',
    String days = '1111111',
    int? remindAt,
    DateTime? createdAt,
  }) {
    // Seri hesabı rutinin oluşturulma gününden geriye gitmez; varsayılan olarak
    // yeterince eski bir tarih verilir.
    return Routine(
      id: id,
      title: title,
      days: days,
      remindAt: remindAt,
      createdAt: createdAt ?? DateTime(2026, 1, 1),
    );
  }

  RoutineCheck check({required int routineId, required DateTime day}) =>
      RoutineCheck(id: routineId * 100, routineId: routineId, day: day, createdAt: day);

  Map<String, dynamic> payload({
    List<Routine> routines = const [],
    List<RoutineCheck> checks = const [],
    List<Document> docs = const [],
    bool dark = false,
    bool en = false,
    bool streaks = true,
  }) {
    return jsonDecode(encodeWidgetPayload(
      dark: dark,
      en: en,
      streaks: streaks,
      routines: routines,
      checks: checks,
      docs: docs,
      now: now,
    )) as Map<String, dynamic>;
  }

  group('gizlilik', () {
    test('kilitli not widget verisine GİRMEZ', () {
      final p = payload(docs: [
        doc(id: 1, title: 'Gizli günlük', locked: true),
        doc(id: 2, title: 'Alışveriş'),
      ]);
      final notes = (p['notes'] as List).cast<Map<String, dynamic>>();
      expect(notes, hasLength(1));
      expect(notes.single['title'], 'Alışveriş');
    });

    test('kilitli notun gövdesi önizlemeye de sızmaz', () {
      final p = payload(docs: [
        doc(id: 1, title: '', locked: true, body: 'parola: 1234'),
      ]);
      expect(p['notes'], isEmpty);
      expect(encodeWidgetPayload(
        dark: false,
        en: false,
        streaks: true,
        routines: const [],
        checks: const [],
        docs: [doc(id: 1, title: '', locked: true, body: 'parola: 1234')],
        now: now,
      ), isNot(contains('1234')));
    });
  });

  group('alan adları (Kotlin WidgetStore ile eşleşmeli)', () {
    test('kök alanlar', () {
      final p = payload(dark: true, en: true, streaks: false);
      expect(p.keys, containsAll(['dark', 'lang', 'streaks', 'routines', 'notes']));
      expect(p['dark'], isTrue);
      expect(p['lang'], 'en');
      expect(p['streaks'], isFalse);
    });

    test('rutin alanları', () {
      final p = payload(routines: [routine(id: 3, days: '1010100')]);
      final r = (p['routines'] as List).first as Map<String, dynamic>;
      expect(r.keys,
          containsAll(['id', 'title', 'days', 'doneDay', 'streak', 'time']));
      expect(r['id'], 3);
      expect(r['days'], '1010100');
    });

    test('belge alanları', () {
      final p = payload(docs: [doc(id: 7, title: 'Ders', type: 'pdf')]);
      final n = (p['notes'] as List).first as Map<String, dynamic>;
      expect(n.keys,
          containsAll(['id', 'title', 'preview', 'time', 'folder', 'pdf']));
      expect(n['id'], 7);
      expect(n['pdf'], isTrue);
      expect(n['folder'], 'Kişisel');
    });
  });

  group('tasarım: rutin saati', () {
    test('hatırlatıcı saati HH:mm olarak gider', () {
      final p = payload(routines: [routine(id: 1, remindAt: 7 * 60)]);
      final r = (p['routines'] as List).first as Map<String, dynamic>;
      expect(r['time'], '07:00');
    });

    test('dakika sıfırdan farklıysa da doğru', () {
      final p = payload(routines: [routine(id: 1, remindAt: 12 * 60 + 30)]);
      final r = (p['routines'] as List).first as Map<String, dynamic>;
      expect(r['time'], '12:30');
    });

    test('hatırlatıcı yoksa saat boştur', () {
      final p = payload(routines: [routine(id: 1)]);
      final r = (p['routines'] as List).first as Map<String, dynamic>;
      expect(r['time'], '');
    });

    test('rutinler saate göre sıralanır, saatsizler sona düşer', () {
      final p = payload(routines: [
        routine(id: 1, title: 'Saatsiz'),
        routine(id: 2, title: 'Akşam', remindAt: 19 * 60),
        routine(id: 3, title: 'Sabah', remindAt: 7 * 60),
      ]);
      final titles = (p['routines'] as List)
          .cast<Map<String, dynamic>>()
          .map((r) => r['title'])
          .toList();
      expect(titles, ['Sabah', 'Akşam', 'Saatsiz']);
    });
  });

  group('rutin durumu', () {
    test('bugün işaretliyse doneDay bugündür', () {
      final p = payload(
        routines: [routine(id: 1)],
        checks: [check(routineId: 1, day: DateTime(2026, 7, 27))],
      );
      final r = (p['routines'] as List).first as Map<String, dynamic>;
      expect(r['doneDay'], '2026-07-27');
    });

    test('hiç işaretlenmemişse doneDay boştur', () {
      final p = payload(routines: [routine(id: 1)]);
      final r = (p['routines'] as List).first as Map<String, dynamic>;
      expect(r['doneDay'], '');
    });

    test('doneDay dünse native taraf bugünü işaretsiz sayabilsin diye dün kalır', () {
      final p = payload(
        routines: [routine(id: 1)],
        checks: [check(routineId: 1, day: DateTime(2026, 7, 26))],
      );
      final r = (p['routines'] as List).first as Map<String, dynamic>;
      expect(r['doneDay'], '2026-07-26');
    });

    test('seri (streak) hesaplanıp gönderilir', () {
      final p = payload(
        routines: [routine(id: 1)],
        checks: [
          check(routineId: 1, day: DateTime(2026, 7, 27)),
          check(routineId: 1, day: DateTime(2026, 7, 26)),
          check(routineId: 1, day: DateTime(2026, 7, 25)),
        ],
      );
      final r = (p['routines'] as List).first as Map<String, dynamic>;
      expect(r['streak'], 3);
    });
  });

  group('sınırlar', () {
    test('en fazla 4 belge gider (4×2 widget satır sayısı)', () {
      final p = payload(docs: [for (var i = 1; i <= 9; i++) doc(id: i)]);
      expect(p['notes'], hasLength(4));
    });

    test('kilitli notlar sayıya dâhil edilmeden 4 belge doldurulur', () {
      final p = payload(docs: [
        doc(id: 1, locked: true),
        for (var i = 2; i <= 8; i++) doc(id: i, title: 'Not $i'),
      ]);
      final notes = (p['notes'] as List).cast<Map<String, dynamic>>();
      expect(notes, hasLength(4));
      expect(notes.first['title'], 'Not 2');
    });

    test('belge zamanı KISA biçimde gider ("… önce" eki yok)', () {
      // Tasarımdaki 2×2 ızgara "Kişisel · 17 sa" istiyor; uzun biçim taşırıyor.
      // Göreli zaman gerçek `DateTime.now()`a göre hesaplanır, o yüzden belge
      // tarihi de ondan türetilir (sabit `now` değil).
      final p = payload(docs: [
        doc(id: 1, updatedAt: DateTime.now().subtract(const Duration(hours: 5))),
      ]);
      final n = (p['notes'] as List).first as Map<String, dynamic>;
      expect(n['time'], '5 sa');
      expect(n['time'], isNot(contains('önce')));
    });

    test('önizleme 40 karakterde kesilir', () {
      final p = payload(docs: [doc(id: 1, body: 'a' * 200)]);
      final n = (p['notes'] as List).first as Map<String, dynamic>;
      expect((n['preview'] as String).length, lessThanOrEqualTo(40));
    });
  });
}
