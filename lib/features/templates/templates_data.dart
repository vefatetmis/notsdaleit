import 'package:flutter/material.dart';

import '../forms/form_model.dart';

/// Uygulamaya gömülü hazır not şablonları. Şablonlar Claude Design
/// "Not Şablonları" handoff'undaki düzenlerin birebir karşılığı olan
/// **form-not** gövdeleri üretir (`features/forms/` — `{"ndform":1,...}`).
/// Boş sayfa şablon değildir (Quill'li serbest not olarak açılır).

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

/// Gömülü bir hazır şablon. [buildBody] o anki dile göre form gövdesi üretir.
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

/// Tüm gömülü hazır şablonlar (design ile birebir: Temel 1 + Boş sayfa tile;
/// Yazı 2; Planlar 3; İş ve Eğitim 3).
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
    pageBackground: 'duz',
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
    pageBackground: 'duz',
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
    pageBackground: 'duz',
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
    pageBackground: 'duz',
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

// ── Form gövdesi kurucular (dile göre) ────────────────────────────────

List<CheckItem> _checks(int n) => [for (var i = 0; i < n; i++) CheckItem()];

String _todoBody(bool en) => FormDoc([
      TitleBlock(text: en ? 'To-do' : 'Yapılacaklar', counter: 'done'),
      FieldsBlock([
        FieldSpec(hint: en ? 'Add a date' : 'Tarih ekle'),
      ]),
      LabelBlock(en ? 'Today' : 'Bugün'),
      ChecklistBlock(
        items: _checks(8),
        addLabel: en ? 'Add task' : 'Görev ekle',
      ),
    ]).encode();

String _journalBody(bool en) => FormDoc([
      LabelBlock(en ? 'Journal' : 'Günlük'),
      TitleBlock(hint: en ? 'July 20, Monday' : '20 Temmuz, Pazartesi'),
      MoodBlock(label: en ? 'My mood' : 'Ruh hâlim'),
      AreaBlock(
        hint: en ? 'What went through my mind today…'
            : 'Bugün aklımdan geçenler…',
        minLines: 12,
      ),
    ]).encode();

String _ideaBody(bool en) => FormDoc([
      TitleBlock(hint: en ? 'Name of the idea' : 'Fikrin adı'),
      LabelBlock(en ? 'In one sentence' : 'Tek cümlede'),
      FieldsBlock([
        FieldSpec(hint: en ? 'What does this idea do?'
            : 'Bu fikir ne yapıyor?'),
      ]),
      LabelBlock(en ? 'Why it matters' : 'Neden önemli'),
      AreaBlock(minLines: 3),
      LabelBlock(en ? 'Next steps' : 'Sonraki adımlar'),
      ChecklistBlock(items: _checks(3)),
      LabelBlock(en ? 'Notes / sketch' : 'Notlar / eskiz'),
      SketchBlock(120),
    ]).encode();

String _dailyBody(bool en) => FormDoc([
      TitleBlock(text: en ? 'Daily Plan' : 'Günlük Plan'),
      FieldsBlock([
        FieldSpec(label: en ? 'Date' : 'Tarih'),
      ]),
      LabelBlock(en ? 'Top 3 priorities' : 'İlk 3 öncelik'),
      NumberedBlock(['', '', '']),
      LabelBlock(en ? 'Schedule' : 'Program'),
      HoursBlock([
        for (final h in [
          '07:00', '08:00', '09:00', '10:00', '11:00', '12:00',
          '13:00', '14:00', '15:00', '16:00', '17:00', '18:00',
        ])
          HourRow(label: h),
      ]),
    ]).encode();

String _weeklyBody(bool en) => FormDoc([
      TitleBlock(text: en ? 'Weekly Plan' : 'Haftalık Plan'),
      FieldsBlock([
        FieldSpec(label: en ? 'Week' : 'Hafta'),
        FieldSpec(
          label: en ? 'Goal' : 'Hedef',
          hint: en ? 'Main goal of the week' : 'Bu haftanın ana hedefi',
          flex: 2,
        ),
      ]),
      WeekBlock([
        for (var d = 0; d < 7; d++)
          WeekDay(
            name: (en
                ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                : ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'])[d],
            faint: d >= 5,
            items: _checks(3),
          ),
      ]),
    ]).encode();

String _shoppingBody(bool en) => FormDoc([
      TitleBlock(
        text: en ? 'Shopping' : 'Alışveriş',
        counter: 'count',
        unit: en ? 'items' : 'ürün',
      ),
      LabelBlock(en ? 'Fruit & veg' : 'Meyve & sebze'),
      ChecklistBlock(items: _checks(3), trailingHint: '1', trailingWidth: 34),
      LabelBlock(en ? 'Dairy & breakfast' : 'Süt & kahvaltı'),
      ChecklistBlock(items: _checks(3), trailingHint: '1', trailingWidth: 34),
      LabelBlock(en ? 'Other' : 'Diğer'),
      ChecklistBlock(
        items: _checks(2),
        trailingHint: '1',
        trailingWidth: 34,
        addLabel: en ? 'Add item' : 'Ürün ekle',
      ),
    ]).encode();

String _meetingBody(bool en) => FormDoc([
      TitleBlock(text: en ? 'Meeting Notes' : 'Toplantı Notu'),
      FieldsBlock([
        FieldSpec(label: en ? 'Date' : 'Tarih'),
        FieldSpec(label: en ? 'Time' : 'Saat'),
      ]),
      FieldsBlock([
        FieldSpec(label: en ? 'Attendees' : 'Katılımcılar'),
      ]),
      FieldsBlock([
        FieldSpec(label: en ? 'Subject' : 'Konu'),
      ]),
      LabelBlock(en ? 'Agenda' : 'Gündem'),
      NumberedBlock(['', '', '']),
      LabelBlock(en ? 'Notes & decisions' : 'Notlar & kararlar'),
      AreaBlock(minLines: 4),
      LabelBlock(en ? 'Action items' : 'Aksiyonlar'),
      ChecklistBlock(
        items: _checks(3),
        trailingHint: en ? 'Who?' : 'Kim?',
        trailingWidth: 60,
      ),
    ]).encode();

String _cornellBody(bool en) => FormDoc([
      FieldsBlock([
        FieldSpec(label: en ? 'Course / topic' : 'Ders / Konu', flex: 3),
        FieldSpec(label: en ? 'Date' : 'Tarih', flex: 2),
      ]),
      CornellBlock(
        cuesLabel: en ? 'Cues / questions' : 'Sorular / İpuçları',
        notesLabel: en ? 'Notes' : 'Notlar',
        summaryLabel: en ? 'Summary' : 'Özet',
      ),
    ]).encode();

String _projectBody(bool en) => FormDoc([
      TitleBlock(text: en ? 'Project Tasks' : 'Proje Görevleri'),
      FieldsBlock([
        FieldSpec(hint: en ? 'Project name' : 'Proje adı'),
      ]),
      FieldsBlock([
        FieldSpec(label: en ? 'Target date' : 'Hedef tarih'),
      ]),
      LabelBlock(en ? 'To do' : 'Yapılacak'),
      ChecklistBlock(items: _checks(3)),
      LabelBlock(en ? 'In progress' : 'Devam ediyor'),
      ChecklistBlock(items: _checks(2)),
      LabelBlock(en ? 'Done' : 'Tamamlandı'),
      ChecklistBlock(items: _checks(2)),
    ]).encode();
