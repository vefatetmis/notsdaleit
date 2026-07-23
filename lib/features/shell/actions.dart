import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

import '../../core/i18n/i18n.dart';
import '../../data/data_providers.dart';
import '../../data/database/database.dart';
import '../drawing/drawing_state.dart';
import '../forms/form_layout.dart';
import '../forms/form_model.dart';
import '../library/new_note_dialog.dart';
import 'shell_state.dart';

/// Belge açılırken araçları sıfırlar. Notlar **yazı modunda** açılır (dokununca
/// klavye gelir); PDF'te çizim/el modunda kalır.
void _resetTools(WidgetRef ref, {required bool isPdf}) {
  ref.read(toolProvider.notifier).state = isPdf ? PenTool.el : PenTool.yazi;
  ref.read(zoomProvider.notifier).state = 1.0;
}

/// Var olan bir belgeyi açar (not → editör, pdf → görüntüleyici).
void openDocument(WidgetRef ref, Document d) {
  final isPdf = d.type == 'pdf';
  _resetTools(ref, isPdf: isPdf);
  ref.read(navProvider.notifier).openDoc(d.id, isPdf: isPdf);
}

/// Yeni not oluşturma akışını başlatır: zengin diyalog (ad + sayfa boyutu +
/// kağıt rengi + şablon ızgarası). Diyalog seçime göre notu oluşturup açar.
Future<void> createNote(BuildContext context, WidgetRef ref) {
  return showNewNoteDialog(context, ref);
}

/// Belirli bir yapılandırmayla (opsiyonel şablon gövdesi + çizimler) yeni not
/// oluşturur ve editörde açar. Yeni not diyaloğu buradan çağırır.
Future<void> createConfiguredNote(
  WidgetRef ref, {
  required String title,
  required String pageSize,
  required String pageColor,
  required String body,
  String pageBackground = 'duz',
  String strokesJson = '[]',
}) async {
  // Form notu ise içeriğine yetecek doğal sayfa sayısını hesapla (manuel sayfa
  // modeli — editörde otomatik büyümez).
  var pageCount = 1;
  if (isFormBody(body)) {
    final form = FormDoc.tryParse(body);
    if (form != null) pageCount = formNaturalPageCount(form, pageSize);
  }

  final id = await ref.read(documentRepositoryProvider).insertNote(
        title: title,
        body: body,
        folder: 'Kişisel',
        pageSize: pageSize,
        pageColor: pageColor,
        pageBackground: pageBackground,
        pageCount: pageCount,
      );

  // Şablon çizimleri (kullanıcı şablonlarında olabilir; gömülülerde yok).
  List<dynamic> strokes = const [];
  try {
    final decoded = jsonDecode(strokesJson);
    if (decoded is List) strokes = decoded;
  } catch (_) {}
  if (strokes.isNotEmpty) {
    final drawRepo = ref.read(drawingRepositoryProvider);
    for (final s in strokes) {
      final m = (s as Map).cast<String, dynamic>();
      await drawRepo.addStroke(
        docId: id,
        page: (m['page'] as int?) ?? 0,
        tool: (m['tool'] as String?) ?? 'kalem',
        color: (m['color'] as int?) ?? 0xFF262626,
        width: (m['width'] as num?)?.toDouble() ?? 5,
        pointsJson: (m['points'] as String?) ?? '[]',
      );
    }
  }

  _resetTools(ref, isPdf: false);
  ref.read(navProvider.notifier).openDoc(id, isPdf: false);
}

/// Cihazdan bir PDF seçtirip uygulama klasörüne kopyalar ve görüntüleyicide açar.
/// Kullanıcı iptal ederse sessizce döner.
Future<void> importPdf(WidgetRef ref) async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
  );
  if (result == null || result.files.isEmpty) return;
  final picked = result.files.first;
  final srcPath = picked.path;
  if (srcPath == null) return;
  await openPdfFromPath(ref, srcPath, name: picked.name);
}

/// Dışarıdan (ör. "Birlikte aç" / paylaş) gelen bir PDF dosya yolunu içe
/// aktarır ve açar. Kopyalar, sayfa sayısını okur, kaydeder, görüntüleyicide açar.
Future<void> openPdfFromPath(WidgetRef ref, String srcPath, {String? name}) async {
  final src = File(srcPath);
  if (!src.existsSync()) return;
  final fileName = name ?? srcPath.split(RegExp(r'[\\/]')).last;

  final appDir = await getApplicationDocumentsDirectory();
  final pdfDir = Directory('${appDir.path}/pdfs');
  if (!pdfDir.existsSync()) pdfDir.createSync(recursive: true);
  final stamp = DateTime.now().millisecondsSinceEpoch;
  final safeName = fileName.toLowerCase().endsWith('.pdf')
      ? fileName
      : '$fileName.pdf';
  final dest = '${pdfDir.path}/${stamp}_$safeName';
  await src.copy(dest);

  var pages = 1;
  try {
    final doc = await PdfDocument.openFile(dest);
    pages = doc.pagesCount;
    await doc.close();
  } catch (_) {
    // Sayfa sayısı okunamazsa 1 kabul edilir.
  }

  final title =
      safeName.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
  final id = await ref.read(documentRepositoryProvider).insertPdf(
        title: title,
        filePath: dest,
        pageCount: pages,
        folder: 'Kişisel',
      );
  _resetTools(ref, isPdf: true);
  ref.read(navProvider.notifier).openDoc(id, isPdf: true);
}

/// Belgeyi **çöp kutusuna** taşır (yumuşak silme) ve "Geri al" bildirimi
/// gösterir. Kalıcı silme değildir — "Son silinenler"den kurtarılabilir.
Future<void> trashDocument(
  BuildContext context,
  WidgetRef ref,
  Document d,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final movedMsg = context.t('Not çöp kutusuna taşındı', 'Moved to trash');
  final undoLabel = context.t('Geri al', 'Undo');
  final repo = ref.read(documentRepositoryProvider);
  await repo.softDelete(d.id);
  if (ref.read(navProvider).activeDocId == d.id) {
    ref.read(navProvider.notifier).back();
  }
  messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      content: Text(movedMsg),
      action: SnackBarAction(
        label: undoLabel,
        onPressed: () => repo.restore(d.id),
      ),
    ));
}

/// Seçili belgeleri sabitler; hepsi zaten sabitse sabitlemeyi kaldırır.
/// İşlem sonrası seçim modundan çıkar.
Future<void> togglePinDocuments(WidgetRef ref, Set<int> ids) async {
  if (ids.isEmpty) return;
  final repo = ref.read(documentRepositoryProvider);
  final docs = ref.read(documentsProvider).valueOrNull ?? const <Document>[];
  final selected = docs.where((d) => ids.contains(d.id)).toList();
  if (selected.isEmpty) return;
  final allPinned = selected.every((d) => d.pinned);
  for (final d in selected) {
    await repo.setPinned(id: d.id, pinned: !allPinned);
  }
  ref.read(librarySelectionProvider.notifier).state = <int>{};
}

/// Seçili birden çok belgeyi çöp kutusuna taşır + "Geri al" bildirimi.
Future<void> trashDocuments(
  BuildContext context,
  WidgetRef ref,
  Set<int> ids,
) async {
  if (ids.isEmpty) return;
  final removed = {...ids};
  final messenger = ScaffoldMessenger.of(context);
  final movedMsg = context.t('${removed.length} öğe çöp kutusuna taşındı',
      '${removed.length} items moved to trash');
  final undoLabel = context.t('Geri al', 'Undo');
  final repo = ref.read(documentRepositoryProvider);
  final activeId = ref.read(navProvider).activeDocId;
  for (final id in removed) {
    await repo.softDelete(id);
  }
  ref.read(librarySelectionProvider.notifier).state = <int>{};
  if (activeId != null && removed.contains(activeId)) {
    ref.read(navProvider.notifier).back();
  }
  messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      content: Text(movedMsg),
      action: SnackBarAction(
        label: undoLabel,
        onPressed: () async {
          for (final id in removed) {
            await repo.restore(id);
          }
        },
      ),
    ));
}

/// Çöp kutusundaki belgeleri geri alır (kütüphaneye döner).
Future<void> restoreDocuments(WidgetRef ref, Set<int> ids) async {
  final repo = ref.read(documentRepositoryProvider);
  for (final id in ids) {
    await repo.restore(id);
  }
}

/// Belgeleri **kalıcı** siler (PDF dosyası + çizimler dâhil). Geri alınamaz;
/// bu yüzden onay ister. "Son silinenler" ekranından kullanılır.
Future<void> permanentlyDeleteDocuments(
  BuildContext context,
  WidgetRef ref,
  Set<int> ids,
) async {
  if (ids.isEmpty) return;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.t('Kalıcı silinsin mi?', 'Delete permanently?')),
      content: Text(context.t(
          '${ids.length} öğe kalıcı olarak silinecek. Bu işlem geri alınamaz.',
          '${ids.length} items will be permanently deleted. This cannot be undone.')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.t('Vazgeç', 'Cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(context.t('Kalıcı sil', 'Delete')),
        ),
      ],
    ),
  );
  if (ok != true) return;

  final repo = ref.read(documentRepositoryProvider);
  for (final id in ids) {
    final d = await repo.getById(id);
    if (d != null && d.type == 'pdf' && d.filePath != null) {
      try {
        final f = File(d.filePath!);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
    }
    await repo.delete(id);
  }
}

/// Çöp kutusundaki tüm belgeleri kalıcı siler (onaylı).
Future<void> emptyTrash(BuildContext context, WidgetRef ref) async {
  final trashed = ref.read(trashedDocumentsProvider).valueOrNull ?? const [];
  if (trashed.isEmpty) return;
  await permanentlyDeleteDocuments(
      context, ref, trashed.map((d) => d.id).toSet());
}
