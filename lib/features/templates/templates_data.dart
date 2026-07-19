import 'dart:convert';

import 'package:flutter/material.dart';

/// Uygulamaya gömülü hazır not şablonları. Her şablon bir başlangıç metni
/// (Quill Delta ops JSON'u) + sayfa boyutu + kağıt rengi taşır. Kullanıcının
/// kendi kaydettikleri ("Şablonlarım") ayrı olarak Templates tablosundadır.

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
    required this.buildBody,
  });

  final String id;
  final String category;
  final String tr;
  final String en;
  final IconData icon;
  final String pageSize;
  final String pageColor;
  final String Function(bool en) buildBody;

  String name(bool en) => en ? this.en : tr;
  String body(bool en) => buildBody(en);
}

/// Delta (Quill ops) gövdesi kurmak için küçük yardımcı. Blok öznitelikleri
/// (list) satır sonundaki '\n' üzerinde taşınır; satır-içi öznitelikler
/// (bold/size) metin parçası üzerinde. Editör ve PDF export'un ikisi de
/// bold/size/list('bullet'|'checked'|'unchecked') render eder.
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

  void title(String s) {
    _run(s, {'bold': true, 'size': '28'});
    _nl();
  }

  void heading(String s) {
    _run(s, {'bold': true, 'size': '22'});
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

  void blank() => _nl();

  String encode() => jsonEncode(_ops);
}

String _delta(void Function(_Delta b) build) {
  final b = _Delta();
  build(b);
  return b.encode();
}

/// Tüm gömülü hazır şablonlar.
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
    buildBody: _todoBody,
  ),
  NoteTemplate(
    id: 'simple',
    category: 'temel',
    tr: 'Basit not',
    en: 'Simple note',
    icon: Icons.notes_rounded,
    pageSize: 'a4',
    pageColor: 'beyaz',
    buildBody: _simpleBody,
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
    buildBody: _projectBody,
  ),
];

// ── Gövde kurucular (dile göre) ───────────────────────────────────────

String _todoBody(bool en) => _delta((b) {
      b.title(en ? 'To-do' : 'Yapılacaklar');
      b.blank();
      b.check(en ? 'First task' : 'İlk görev');
      b.check(en ? 'Second task' : 'İkinci görev');
      b.check(en ? 'Third task' : 'Üçüncü görev');
    });

String _simpleBody(bool en) => _delta((b) {
      b.title(en ? 'Title' : 'Başlık');
      b.blank();
      b.para(en ? 'Start writing here…' : 'Buraya yazmaya başlayın…');
    });

String _journalBody(bool en) => _delta((b) {
      b.title(en ? 'Dear diary' : 'Sevgili günlük');
      b.para(en ? 'Date: ____ / ____ / ______' : 'Tarih: ____ / ____ / ______');
      b.blank();
      b.heading(en ? 'How I feel today' : 'Bugün nasıl hissediyorum');
      b.para(en ? 'Write here…' : 'Buraya yazın…');
      b.blank();
      b.heading(en ? 'Grateful for' : 'Şükrettiklerim');
      b.bullet('');
      b.bullet('');
    });

String _ideaBody(bool en) => _delta((b) {
      b.title(en ? 'Idea' : 'Fikir');
      b.blank();
      b.heading(en ? 'What is it?' : 'Nedir?');
      b.para(en ? 'Describe the idea…' : 'Fikri anlatın…');
      b.blank();
      b.heading(en ? 'Next steps' : 'Sonraki adımlar');
      b.check(en ? 'Step one' : 'Birinci adım');
      b.check(en ? 'Step two' : 'İkinci adım');
    });

String _dailyBody(bool en) => _delta((b) {
      b.title(en ? 'Daily plan' : 'Günlük plan');
      b.para(en ? 'Date: ____ / ____ / ______' : 'Tarih: ____ / ____ / ______');
      b.blank();
      b.heading(en ? 'Top 3 priorities' : 'Öncelikli 3 iş');
      b.check('');
      b.check('');
      b.check('');
      b.blank();
      b.heading(en ? 'Schedule' : 'Program');
      b.bullet(en ? '09:00 · ' : '09:00 · ');
      b.bullet(en ? '12:00 · ' : '12:00 · ');
      b.bullet(en ? '15:00 · ' : '15:00 · ');
      b.bullet(en ? '18:00 · ' : '18:00 · ');
      b.blank();
      b.heading(en ? 'Notes' : 'Notlar');
      b.para('');
    });

String _weeklyBody(bool en) => _delta((b) {
      b.title(en ? 'Weekly plan' : 'Haftalık plan');
      b.blank();
      final days = en
          ? ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Weekend']
          : [
              'Pazartesi',
              'Salı',
              'Çarşamba',
              'Perşembe',
              'Cuma',
              'Hafta sonu'
            ];
      for (final d in days) {
        b.heading(d);
        b.check('');
        b.blank();
      }
    });

String _shoppingBody(bool en) => _delta((b) {
      b.title(en ? 'Shopping' : 'Alışveriş');
      b.blank();
      b.check('');
      b.check('');
      b.check('');
      b.check('');
      b.check('');
      b.check('');
    });

String _meetingBody(bool en) => _delta((b) {
      b.title(en ? 'Meeting notes' : 'Toplantı notu');
      b.para(en ? 'Date: ______   ·   Attendees: ______'
          : 'Tarih: ______   ·   Katılımcılar: ______');
      b.blank();
      b.heading(en ? 'Agenda' : 'Gündem');
      b.bullet('');
      b.bullet('');
      b.blank();
      b.heading(en ? 'Decisions' : 'Kararlar');
      b.bullet('');
      b.blank();
      b.heading(en ? 'Action items' : 'Yapılacaklar');
      b.check('');
      b.check('');
    });

String _cornellBody(bool en) => _delta((b) {
      b.title(en ? 'Cornell notes' : 'Cornell notu');
      b.para(en ? 'Topic: ______   ·   Date: ______'
          : 'Konu: ______   ·   Tarih: ______');
      b.blank();
      b.heading(en ? 'Cues / Questions' : 'İpuçları / Sorular');
      b.bullet('');
      b.blank();
      b.heading(en ? 'Notes' : 'Notlar');
      b.para('');
      b.para('');
      b.blank();
      b.heading(en ? 'Summary' : 'Özet');
      b.para('');
    });

String _projectBody(bool en) => _delta((b) {
      b.title(en ? 'Project' : 'Proje');
      b.blank();
      b.heading(en ? 'Goal' : 'Hedef');
      b.para('');
      b.blank();
      b.heading(en ? 'Tasks' : 'Görevler');
      b.check('');
      b.check('');
      b.check('');
      b.blank();
      b.heading(en ? 'Blocked' : 'Bekleyenler');
      b.bullet('');
    });
