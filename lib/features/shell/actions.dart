import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/nd_colors.dart';
import '../../data/data_providers.dart';
import '../../data/database/database.dart';
import '../drawing/drawing_state.dart';
import 'shell_state.dart';

void _resetTools(WidgetRef ref) {
  ref.read(toolProvider.notifier).state = PenTool.el;
  ref.read(zoomProvider.notifier).state = 1.0;
}

/// Var olan bir belgeyi açar (not → editör, pdf → görüntüleyici).
void openDocument(WidgetRef ref, Document d) {
  _resetTools(ref);
  ref.read(navProvider.notifier).openDoc(d.id, isPdf: d.type == 'pdf');
}

/// Yeni not oluşturur. Önce sayfa boyutunu sorar (A4 / Kare), sonra editörde
/// açar. Kullanıcı iptal ederse hiçbir şey yapmaz.
Future<void> createNote(BuildContext context, WidgetRef ref) async {
  final size = await _pickNoteSize(context);
  if (size == null) return;

  final id = await ref.read(documentRepositoryProvider).insertNote(
        title: '',
        body: '',
        folder: 'Kişisel',
        pageSize: size,
        pageCount: 1,
      );
  _resetTools(ref);
  ref.read(navProvider.notifier).openDoc(id, isPdf: false);
}

Future<String?> _pickNoteSize(BuildContext context) {
  final nd = context.nd;
  Widget option(IconData icon, String title, String subtitle, String value) {
    return ListTile(
      leading: Icon(icon, color: nd.text2),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(subtitle,
          style: TextStyle(fontSize: 12.5, color: nd.text2)),
      onTap: () => Navigator.of(context).pop(value),
    );
  }

  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: nd.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: nd.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(context.t('Yeni not', 'New note'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          option(
              Icons.description_outlined,
              context.t('A4 sayfa', 'A4 page'),
              context.t('Dikey sayfa · yaz veya çiz',
                  'Portrait page · write or draw'),
              'a4'),
          option(
              Icons.crop_square_outlined,
              context.t('Kare sayfa', 'Square page'),
              context.t('Kare sayfa · yaz veya çiz',
                  'Square page · write or draw'),
              'kare'),
          const SizedBox(height: 10),
        ],
      ),
    ),
  );
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
  _resetTools(ref);
  ref.read(navProvider.notifier).openDoc(id, isPdf: true);
}

/// Onay isteyip belgeyi (ve varsa PDF dosyasını + çizimlerini) siler.
Future<void> confirmDeleteDocument(
  BuildContext context,
  WidgetRef ref,
  Document d,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.t('Silinsin mi?', 'Delete?')),
      content: Text(context.t(
          '"${d.title.isEmpty ? 'Adsız' : d.title}" kalıcı olarak silinecek.',
          '“${d.title.isEmpty ? 'Untitled' : d.title}” will be permanently deleted.')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.t('Vazgeç', 'Cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(context.t('Sil', 'Delete')),
        ),
      ],
    ),
  );
  if (ok != true) return;

  if (d.type == 'pdf' && d.filePath != null) {
    try {
      final f = File(d.filePath!);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }
  await ref.read(documentRepositoryProvider).delete(d.id);
  if (ref.read(navProvider).activeDocId == d.id) {
    ref.read(navProvider.notifier).back();
  }
}

/// Onay isteyip seçili birden çok belgeyi (ve PDF dosyalarını) siler.
Future<void> confirmDeleteDocuments(
  BuildContext context,
  WidgetRef ref,
  Set<int> ids,
) async {
  if (ids.isEmpty) return;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.t('Silinsin mi?', 'Delete?')),
      content: Text(context.t(
          '${ids.length} öğe kalıcı olarak silinecek.',
          '${ids.length} items will be permanently deleted.')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.t('Vazgeç', 'Cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(context.t('Sil', 'Delete')),
        ),
      ],
    ),
  );
  if (ok != true) return;

  final repo = ref.read(documentRepositoryProvider);
  final activeId = ref.read(navProvider).activeDocId;
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
  ref.read(librarySelectionProvider.notifier).state = <int>{};
  if (activeId != null && ids.contains(activeId)) {
    ref.read(navProvider.notifier).back();
  }
}
