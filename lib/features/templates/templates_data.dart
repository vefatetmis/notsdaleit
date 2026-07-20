import 'dart:convert';

import 'package:flutter/material.dart';

/// Uygulamaya gömülü hazır not şablonları. Her şablon bir başlangıç metni
/// (Quill Delta ops JSON'u) + sayfa boyutu + kağıt rengi + sayfa deseni taşır.
/// İçerik ve düzen, Claude Design "Not Şablonları" handoff'una göre kurulmuştur
/// (pragmatik: metin + bölüm etiketi + kutucuk + çizgili/noktalı arka plan;
/// gerçek ızgara/2-kolon düzen editör tablo bloğu gelince tam yapılacak).

/// Şablon kategorileri (yeni not diyaloğundaki sekmeler). 'benim' sekmesi
/// kullanıcı şablonları içindir ve buradaki gömülü listede yer almaz.
class TemplateCategory {
  const TemplateCategory(this.key, this.tr, this.en);
  final String key;
  final String tr;
  final String en;
}

const List<TemplateCategory> kTemplateCategories = [
  TemplateCategory('temel', 'Temel', 'Basic'),
  TemplateCategory('yazi', 'Yazı', 'Writing'),
  TemplateCategory('planlar', 'Planlar', 'Plans'),
  TemplateCategory('is', 'İş ve Eğitim', 'Work & Study'),
  TemplateCategory('benim', 'Şablonlarım', 'My templates'),
];

/// Gömülü bir hazır şablon. [buildBody] o anki dile göre Delta gövdesi üretir.
class NoteTemplate {
  const NoteTemplate({
    required this.id,
    required this.category,
    required this.tr,
    required this.en,
    required this.icon,
    required this.pageSize,
    required this.pageColor,
    required this.pageBackground,
    required this.buildBody,
  });

  final String id;
  final String category;
  final String tr;
  final String en;
  final IconData icon;
  final String pageSize;
  final String pageColor;
  final String pageBackground;
  final String Function(bool en) buildBody;

  String name(bool en) => en ? this.en : tr;
  String body(bool en) => buildBody(en);
}

/// Delta (Quill ops) gövdesi kurmak için küçük yardımcı. Blok öznitelikleri
/// (list) satır sonundaki '\n' üzerinde taşınır; satır-içi öznitelikler
/// (bold/size) metin parçası üzerinde. Editör ve PDF export'un ikisi de
/// bold/size/list('bullet'|'checked'|'unchecked') render eder. Renk özniteliği
/// kullanılmaz → yazı rengi kâğıda göre otomatik ayarlanır (siyah kâğıtta beyaz).
class _Delta {
  final List<Map<String, dynamic>> _ops = [];

  void _run(String text, [Map<String, dynamic>? attr]) {
    _ops.add({
      'insert': text,
      if (attr != null && attr.isNotEmpty) 'attributes': attr,
    });
  }

  void _nl([Map<String, dynamic>? attr]) {
    _ops.add({
      'insert': '\n',
      if (attr != null && attr.isNotEmpty) 'attributes': attr,
    });
  }

  /// Büyük başlık.
  void title(String s) {
    _run(s, {'bold': true, 'size': '22'});
    _nl();
  }

  /// Orta başlık (bölüm başlığı).
  void heading(String s) {
    _run(s, {'bold': true, 'size': '18'});
    _nl();
  }

  /// Küçük büyük-harf bölüm etiketi (design'daki "BUGÜN", "PROGRAM" gibi).
  void label(String s) {
    _run(s.toUpperCase(), {'bold': true, 'size': '12'});
    _nl();
  }

  void para(String s, {bool bold = false}) {
    _run(s, {if (bold) 'bold': true});
    _nl();
  }

  void bullet(String s) {
    _run(s);
    _nl({'list': 'bullet'});
  }

  void check(String s, {bool done = false}) {
    _run(s);
    _nl({'list': done ? 'checked' : 'unchecked'});
  }

  /// Tablo/ızgara bloğu ('ndtable' embed — `table_embed.dart`).
  /// [rows] kısa-anahtar hücre map'leri: t=metin, k=0 kutucuk, m=1 soluk
  /// etiket, f=1 hafif zemin, n=min satır sayısı.
  void table({
    required List<int> widths,
    bool header = false,
    required List<List<Map<String, dynamic>>> rows,
  }) {
    _ops.add({
      'insert': {
        'ndtable': jsonEncode({
          'w': widths,
          if (header) 'h': 1,
          'r': rows,
        }),
      },
    });
    _nl();
  }

  void blank() => _nl();

  String encode() => jsonEncode(_ops);
}

String _delta(void Function(_Delta b) build) {
  final b = _Delta();
  build(b);
  return b.encode();
}

/// Tüm gömülü hazır şablonlar (kategoriler design ile birebir: Temel 1 + Boş
/// sayfa tile'ı, Yazı 2, Planlar 3, İş ve Eğitim 3).
const List<NoteTemplate> kBuiltInTemplates = [
  // ── Temel ──────────────────────────────────────────────────────────
  NoteTemplate(
    id: 'todo',
    category: 'temel',
    tr: 'Yapılacaklar',
    en: 'To-do list',
    icon: Icons.checklist_rounded,
    pageSize: 'a4',
    pageColor: 'beyaz',
    pageBackground: 'duz',
    buildBody: _todoBody,
  ),
  // ── Yazı ───────────────────────────────────────────────────────────
  NoteTemplate(
    id: 'journal',
    category: 'yazi',
    tr: 'Günlük',
    en: 'Journal',
    icon: Icons.auto_stories_rounded,
    pageSize: 'a4',
    pageColor: 'sari',
    pageBackground: 'cizgili',
    buildBody: _journalBody,
  ),
  NoteTemplate(
    id: 'idea',
    category: 'yazi',
    tr: 'Fikir defteri',
    en: 'Idea notebook',
    icon: Icons.lightbulb_outline_rounded,
    pageSize: 'a4',
    pageColor: 'beyaz',
    pageBackground: 'noktali',
    buildBody: _ideaBody,
  ),
  // ── Planlar ────────────────────────────────────────────────────────
  NoteTemplate(
    id: 'daily',
    category: 'planlar',
    tr: 'Günlük plan',
    en: 'Daily plan',
    icon: Icons.today_rounded,
    pageSize: 'a4',
    pageColor: 'beyaz',
    pageBackground: 'duz',
    buildBody: _dailyBody,
  ),
  NoteTemplate(
    id: 'weekly',
    category: 'planlar',
    tr: 'Haftalık plan',
    en: 'Weekly plan',
    icon: Icons.view_week_rounded,
    pageSize: 'yatay',
    pageColor: 'beyaz',
    pageBackground: 'duz',
    buildBody: _weeklyBody,
  ),
  NoteTemplate(
    id: 'shopping',
    category: 'planlar',
    tr: 'Alışveriş listesi',
    en: 'Shopping list',
    icon: Icons.shopping_cart_outlined,
    pageSize: 'telefon',
    pageColor: 'beyaz',
    pageBackground: 'duz',
    buildBody: _shoppingBody,
  ),
  // ── İş ve Eğitim ───────────────────────────────────────────────────
  NoteTemplate(
    id: 'meeting',
    category: 'is',
    tr: 'Toplantı notu',
    en: 'Meeting notes',
    icon: Icons.groups_outlined,
    pageSize: 'a4',
    pageColor: 'beyaz',
    pageBackground: 'cizgili',
    buildBody: _meetingBody,
  ),
  NoteTemplate(
    id: 'cornell',
    category: 'is',
    tr: 'Cornell notu',
    en: 'Cornell notes',
    icon: Icons.school_outlined,
    pageSize: 'a4',
    pageColor: 'beyaz',
    pageBackground: 'cizgili',
    buildBody: _cornellBody,
  ),
  NoteTemplate(
    id: 'project',
    category: 'is',
    tr: 'Proje görevleri',
    en: 'Project tasks',
    icon: Icons.task_alt_rounded,
    pageSize: 'a4',
    pageColor: 'beyaz',
    pageBackground: 'duz',
    buildBody: _projectBody,
  ),
];

// ── Gövde kurucular (dile göre) ───────────────────────────────────────

String _todoBody(bool en) => _delta((b) {
      b.title(en ? 'To-do' : 'Yapılacaklar');
      b.blank();
      b.label(en ? 'Today' : 'Bugün');
      b.check('');
      b.check('');
      b.check('');
      b.check('');
      b.check('');
      b.check('');
    });

String _journalBody(bool en) => _delta((b) {
      b.label(en ? 'Journal' : 'Günlük');
      b.title(en ? 'Today' : 'Bugün');
      b.para(en ? 'Date: ____ / ____ / ______' : 'Tarih: ____ / ____ / ______');
      b.blank();
      b.heading(en ? 'How I feel today' : 'Bugün nasıl hissediyorum');
      b.para('');
      b.para('');
      b.blank();
      b.heading(en ? 'Grateful for' : 'Şükrettiklerim');
      b.bullet('');
      b.bullet('');
    });

String _ideaBody(bool en) => _delta((b) {
      b.title(en ? 'Idea' : 'Fikir');
      b.blank();
      b.label(en ? 'In one sentence' : 'Tek cümlede');
      b.para(en ? 'What does this idea do?' : 'Bu fikir ne yapıyor?');
      b.blank();
      b.label(en ? 'Why it matters' : 'Neden önemli');
      b.para('');
      b.para('');
      b.blank();
      b.label(en ? 'Next steps' : 'Sonraki adımlar');
      b.check('');
      b.check('');
    });

String _dailyBody(bool en) => _delta((b) {
      b.title(en ? 'Daily Plan' : 'Günlük Plan');
      b.para(en ? 'Date: ______' : 'Tarih: ______');
      b.blank();
      b.label(en ? 'Top 3 priorities' : 'İlk 3 öncelik');
      b.check('');
      b.check('');
      b.check('');
      b.blank();
      b.label(en ? 'Schedule' : 'Program');
      b.table(
        widths: const [1, 4],
        rows: [
          for (final h in [
            '07:00',
            '08:00',
            '09:00',
            '10:00',
            '11:00',
            '12:00',
            '13:00',
            '14:00',
            '15:00',
            '16:00',
            '17:00',
            '18:00'
          ])
            [
              {'t': h, 'm': 1},
              <String, dynamic>{},
            ],
        ],
      );
    });

String _weeklyBody(bool en) => _delta((b) {
      b.title(en ? 'Weekly Plan' : 'Haftalık Plan');
      b.para(en ? 'Week: ______   ·   Goal: ______'
          : 'Hafta: ______   ·   Hedef: ______');
      b.blank();
      final days = en
          ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
          : ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
      b.table(
        widths: const [1, 1, 1, 1, 1, 1, 1],
        header: true,
        rows: [
          [for (final d in days) {'t': d}],
          for (var r = 0; r < 3; r++)
            [
              for (var c = 0; c < 7; c++)
                {'k': 0, if (c >= 5) 'f': 1},
            ],
        ],
      );
    });

String _shoppingBody(bool en) => _delta((b) {
      b.title(en ? 'Shopping' : 'Alışveriş');
      b.blank();
      final sections = en
          ? ['Fruit & veg', 'Dairy & breakfast', 'Other']
          : ['Meyve & sebze', 'Süt & kahvaltı', 'Diğer'];
      for (final s in sections) {
        b.label(s);
        b.table(
          widths: const [5, 1],
          rows: [
            for (var r = 0; r < 3; r++)
              [
                {'k': 0},
                {'m': 1},
              ],
          ],
        );
        b.blank();
      }
    });

String _meetingBody(bool en) => _delta((b) {
      b.title(en ? 'Meeting Notes' : 'Toplantı Notu');
      b.blank();
      b.table(
        widths: const [1, 1],
        header: true,
        rows: [
          [
            {'t': en ? 'DATE' : 'TARİH'},
            {'t': en ? 'TIME' : 'SAAT'},
          ],
          [<String, dynamic>{}, <String, dynamic>{}],
        ],
      );
      b.table(
        widths: const [1, 1],
        header: true,
        rows: [
          [
            {'t': en ? 'ATTENDEES' : 'KATILIMCILAR'},
            {'t': en ? 'SUBJECT' : 'KONU'},
          ],
          [<String, dynamic>{}, <String, dynamic>{}],
        ],
      );
      b.blank();
      b.label(en ? 'Agenda' : 'Gündem');
      b.para('1. ');
      b.para('2. ');
      b.para('3. ');
      b.blank();
      b.label(en ? 'Notes & decisions' : 'Notlar & kararlar');
      b.para('');
      b.para('');
      b.blank();
      b.label(en ? 'Action items' : 'Aksiyonlar');
      b.table(
        widths: const [4, 2],
        header: true,
        rows: [
          [
            {'t': en ? 'ACTION' : 'AKSİYON'},
            {'t': en ? 'WHO' : 'KİM'},
          ],
          for (var r = 0; r < 3; r++)
            [
              {'k': 0},
              <String, dynamic>{},
            ],
        ],
      );
    });

String _cornellBody(bool en) => _delta((b) {
      b.title(en ? 'Cornell Notes' : 'Cornell Notu');
      b.para(en ? 'Topic: ______   ·   Date: ______'
          : 'Ders/Konu: ______   ·   Tarih: ______');
      b.blank();
      b.table(
        widths: const [2, 3],
        header: true,
        rows: [
          [
            {'t': en ? 'CUES / QUESTIONS' : 'SORULAR / İPUÇLARI'},
            {'t': en ? 'NOTES' : 'NOTLAR'},
          ],
          [
            {'f': 1, 'n': 12},
            {'n': 12},
          ],
        ],
      );
      b.table(
        widths: const [1],
        header: true,
        rows: [
          [
            {'t': en ? 'SUMMARY' : 'ÖZET'},
          ],
          [
            {'n': 3},
          ],
        ],
      );
    });

String _projectBody(bool en) => _delta((b) {
      b.title(en ? 'Project Tasks' : 'Proje Görevleri');
      b.para(en ? 'Project: ______   ·   Due: ______'
          : 'Proje: ______   ·   Hedef tarih: ______');
      b.blank();
      b.label(en ? 'To do' : 'Yapılacak');
      b.check('');
      b.check('');
      b.check('');
      b.blank();
      b.label(en ? 'In progress' : 'Devam ediyor');
      b.check('');
      b.check('');
      b.blank();
      b.label(en ? 'Done' : 'Tamamlandı');
      b.check('');
      b.check('');
    });
