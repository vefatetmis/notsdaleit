import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/i18n.dart';
import '../../data/data_providers.dart';
import '../../data/database/database.dart';

/// Tüm kullanıcı verisini tek bir `.ntdlbak` (JSON) dosyasına yedekler ve geri
/// yükler. PDF **dosyaları** dâhil DEĞİLDİR (kullanıcı kararı) — notlar (yazı +
/// çizim), etiketler, klasörler, görevler, rutinler ve şablonlar yedeklenir.
///
/// Geri yükleme **birleştirmedir** (mevcut verinin üzerine yazmaz, ekler) —
/// boş cihaza taşımada birebir, dolu cihazda kopya oluşturabilir.

const _kBackupFormat = 'ntdlbak';
const _kBackupVersion = 1;

String _iso(DateTime d) => d.toIso8601String();
DateTime _parseDate(dynamic v) =>
    DateTime.tryParse(v as String? ?? '') ?? DateTime.now();

/// Tüm veriyi toplayıp kullanıcıya kayıt konumu sordurarak dışa aktarır.
Future<void> exportBackup(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final okMsg = context.t('Yedek kaydedildi', 'Backup saved');
  final failMsg = context.t('Yedek kaydedilemedi', 'Backup could not be saved');
  final saveTitle = context.t('Yedeği kaydet', 'Save backup');

  final db = ref.read(databaseProvider);

  // Notlar (çöp kutusundakiler ve PDF'ler hariç). deletedAt filtresini Dart'ta
  // uyguluyoruz (drift '&' operatörü tam import gerektirir, o da Flutter'ın
  // Column/Table adlarıyla çakışır).
  final allNotes =
      await (db.select(db.documents)..where((t) => t.type.equals('not'))).get();
  final notes = allNotes.where((n) => n.deletedAt == null).toList();

  // Çizimleri ve etiket bağlarını tek seferde okuyup grupla.
  final allStrokes = await db.select(db.strokes).get();
  final strokesByDoc = <int, List<Stroke>>{};
  for (final s in allStrokes) {
    (strokesByDoc[s.docId] ??= []).add(s);
  }

  final allTags = await db.select(db.tags).get();
  final tagNameById = {for (final t in allTags) t.id: t.name};
  final links = await db.select(db.documentTags).get();
  final tagNamesByDoc = <int, List<String>>{};
  for (final l in links) {
    final name = tagNameById[l.tagId];
    if (name != null) (tagNamesByDoc[l.docId] ??= []).add(name);
  }

  final folders = await db.select(db.folders).get();
  final tasks = await db.select(db.tasks).get();
  final dayNotes = await db.select(db.dayNotes).get();
  final routines = await db.select(db.routines).get();
  final checks = await db.select(db.routineChecks).get();
  final checksByRoutine = <int, List<RoutineCheck>>{};
  for (final c in checks) {
    (checksByRoutine[c.routineId] ??= []).add(c);
  }
  final templates = await db.select(db.templates).get();

  final data = <String, dynamic>{
    'format': _kBackupFormat,
    'version': _kBackupVersion,
    'exportedAt': _iso(DateTime.now()),
    'notes': [
      for (final n in notes)
        {
          'title': n.title,
          'folder': n.folder,
          'body': n.body,
          'pageSize': n.pageSize,
          'pageColor': n.pageColor,
          'pageBackground': n.pageBackground,
          'pageCount': n.pageCount,
          'pinned': n.pinned,
          'createdAt': _iso(n.createdAt),
          'updatedAt': _iso(n.updatedAt),
          'tags': tagNamesByDoc[n.id] ?? const [],
          'strokes': [
            for (final s in strokesByDoc[n.id] ?? const [])
              {
                'page': s.page,
                'tool': s.tool,
                'color': s.color,
                'width': s.width,
                'points': s.points,
              },
          ],
        },
    ],
    'folders': [for (final f in folders) f.name],
    'tags': [for (final t in allTags) t.name],
    'tasks': [
      for (final t in tasks)
        {
          'title': t.title,
          'done': t.done,
          'dueDate': t.dueDate == null ? null : _iso(t.dueDate!),
          'remindAt': t.remindAt == null ? null : _iso(t.remindAt!),
          'createdAt': _iso(t.createdAt),
        },
    ],
    'dayNotes': [
      for (final d in dayNotes)
        {'day': _iso(d.day), 'body': d.body, 'updatedAt': _iso(d.updatedAt)},
    ],
    'routines': [
      for (final r in routines)
        {
          'title': r.title,
          'days': r.days,
          'remindAt': r.remindAt,
          'createdAt': _iso(r.createdAt),
          'checkDays': [
            for (final c in checksByRoutine[r.id] ?? const []) _iso(c.day),
          ],
        },
    ],
    'templates': [
      for (final t in templates)
        {
          'title': t.title,
          'pageSize': t.pageSize,
          'pageColor': t.pageColor,
          'pageBackground': t.pageBackground,
          'body': t.body,
          'strokes': t.strokes,
          'createdAt': _iso(t.createdAt),
        },
    ],
  };

  try {
    final stamp = DateTime.now();
    final fileName =
        'notsdaleit-yedek-${stamp.year}${_pad2(stamp.month)}${_pad2(stamp.day)}.ntdlbak';
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(data)));
    final path = await FilePicker.saveFile(
      dialogTitle: saveTitle,
      fileName: fileName,
      bytes: bytes,
    );
    messenger.showSnackBar(
        SnackBar(content: Text(path == null ? failMsg : okMsg)));
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(failMsg)));
  }
}

String _pad2(int n) => n.toString().padLeft(2, '0');

/// Kullanıcıdan bir `.ntdlbak` seçtirip verileri **mevcut verilere ekleyerek**
/// geri yükler (birleştirme). Önce onay ister.
Future<void> importBackup(BuildContext context, WidgetRef ref) async {
  final res = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['ntdlbak', 'json'],
  );
  final path = res?.files.isNotEmpty == true ? res!.files.first.path : null;
  if (path == null) return;

  String raw;
  try {
    raw = await File(path).readAsString();
  } catch (_) {
    if (context.mounted) _invalidToast(context);
    return;
  }
  Map<String, dynamic> data;
  try {
    data = jsonDecode(raw) as Map<String, dynamic>;
  } catch (_) {
    if (context.mounted) _invalidToast(context);
    return;
  }
  if (data['format'] != _kBackupFormat) {
    if (context.mounted) _invalidToast(context);
    return;
  }

  final noteCount = (data['notes'] as List?)?.length ?? 0;
  if (!context.mounted) return;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.t('Geri yüklensin mi?', 'Restore backup?')),
      content: Text(context.t(
          'Yedekteki $noteCount not (ve etiketler, klasörler, görevler, '
              'rutinler, şablonlar) mevcut verilere EKLENECEK — üzerine '
              'yazılmaz. Boş bir cihaza geri yüklüyorsan birebir taşınır.',
          '$noteCount notes from the backup (plus tags, folders, tasks, '
              'routines, templates) will be ADDED to your current data — '
              'nothing is overwritten. On a fresh device this is an exact copy.')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.t('Vazgeç', 'Cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(context.t('Geri yükle', 'Restore')),
        ),
      ],
    ),
  );
  if (ok != true) return;

  final restored = await _restore(ref, data);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(context.t('$restored not geri yüklendi',
          '$restored notes restored')),
    ));
  }
}

void _invalidToast(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(context.t('Geçersiz yedek dosyası', 'Invalid backup file')),
  ));
}

/// Verileri veritabanına ekler (birleştirme). Geri yüklenen not sayısını döner.
Future<int> _restore(WidgetRef ref, Map<String, dynamic> data) async {
  final db = ref.read(databaseProvider);
  final folderRepo = ref.read(folderRepositoryProvider);
  final tagRepo = ref.read(tagRepositoryProvider);

  // Klasörler.
  for (final f in (data['folders'] as List?) ?? const []) {
    if (f is String) await folderRepo.add(f);
  }
  // Etiket kataloğu (kullanılmayanlar da yaşasın).
  for (final t in (data['tags'] as List?) ?? const []) {
    if (t is String) await tagRepo.ensureTag(t);
  }

  // Notlar + çizimleri + etiketleri.
  var restored = 0;
  for (final raw in (data['notes'] as List?) ?? const []) {
    final n = (raw as Map).cast<String, dynamic>();
    final docId = await db.into(db.documents).insert(
          DocumentsCompanion.insert(
            type: 'not',
            title: Value((n['title'] as String?) ?? ''),
            folder: Value((n['folder'] as String?) ?? 'Kişisel'),
            body: Value((n['body'] as String?) ?? ''),
            pageSize: Value((n['pageSize'] as String?) ?? 'serbest'),
            pageColor: Value((n['pageColor'] as String?) ?? 'beyaz'),
            pageBackground: Value((n['pageBackground'] as String?) ?? 'duz'),
            pageCount: Value(n['pageCount'] as int?),
            pinned: Value((n['pinned'] as bool?) ?? false),
            createdAt: _parseDate(n['createdAt']),
            updatedAt: _parseDate(n['updatedAt']),
          ),
        );
    for (final s in (n['strokes'] as List?) ?? const []) {
      final m = (s as Map).cast<String, dynamic>();
      await db.into(db.strokes).insert(
            StrokesCompanion.insert(
              docId: docId,
              page: Value((m['page'] as int?) ?? 0),
              tool: (m['tool'] as String?) ?? 'kalem',
              color: Value((m['color'] as int?) ?? 0xFF262626),
              width: Value((m['width'] as num?)?.toDouble() ?? 5),
              points: (m['points'] as String?) ?? '[]',
              createdAt: DateTime.now(),
            ),
          );
    }
    for (final tagName in (n['tags'] as List?) ?? const []) {
      if (tagName is! String) continue;
      final tagId = await tagRepo.ensureTag(tagName);
      if (tagId > 0) await tagRepo.addLink(docId, tagId);
    }
    restored++;
  }

  // Görevler.
  for (final raw in (data['tasks'] as List?) ?? const []) {
    final t = (raw as Map).cast<String, dynamic>();
    await db.into(db.tasks).insert(
          TasksCompanion.insert(
            title: (t['title'] as String?) ?? '',
            done: Value((t['done'] as bool?) ?? false),
            dueDate: Value(
                t['dueDate'] == null ? null : _parseDate(t['dueDate'])),
            remindAt: Value(
                t['remindAt'] == null ? null : _parseDate(t['remindAt'])),
            createdAt: _parseDate(t['createdAt']),
          ),
        );
  }

  // Gün notları.
  for (final raw in (data['dayNotes'] as List?) ?? const []) {
    final d = (raw as Map).cast<String, dynamic>();
    await db.into(db.dayNotes).insert(
          DayNotesCompanion.insert(
            day: _parseDate(d['day']),
            body: Value((d['body'] as String?) ?? ''),
            updatedAt: _parseDate(d['updatedAt']),
          ),
        );
  }

  // Rutinler + tamamlama kayıtları.
  for (final raw in (data['routines'] as List?) ?? const []) {
    final r = (raw as Map).cast<String, dynamic>();
    final routineId = await db.into(db.routines).insert(
          RoutinesCompanion.insert(
            title: (r['title'] as String?) ?? '',
            days: Value((r['days'] as String?) ?? '1111111'),
            remindAt: Value(r['remindAt'] as int?),
            createdAt: _parseDate(r['createdAt']),
          ),
        );
    for (final cd in (r['checkDays'] as List?) ?? const []) {
      await db.into(db.routineChecks).insert(
            RoutineChecksCompanion.insert(
              routineId: routineId,
              day: _parseDate(cd),
              createdAt: DateTime.now(),
            ),
          );
    }
  }

  // Şablonlar.
  for (final raw in (data['templates'] as List?) ?? const []) {
    final t = (raw as Map).cast<String, dynamic>();
    await db.into(db.templates).insert(
          TemplatesCompanion.insert(
            title: Value((t['title'] as String?) ?? ''),
            pageSize: Value((t['pageSize'] as String?) ?? 'a4'),
            pageColor: Value((t['pageColor'] as String?) ?? 'beyaz'),
            pageBackground: Value((t['pageBackground'] as String?) ?? 'duz'),
            body: Value((t['body'] as String?) ?? ''),
            strokes: Value((t['strokes'] as String?) ?? '[]'),
            createdAt: _parseDate(t['createdAt']),
          ),
        );
  }

  return restored;
}
