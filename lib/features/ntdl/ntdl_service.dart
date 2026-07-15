import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
import '../../data/database/database.dart';
import '../drawing/drawing_state.dart';
import '../shell/shell_state.dart';

/// notsdaleit'in kendi biçimi `.ntdl`: bir notu (metin + sayfa ayarı + çizimler)
/// tek bir JSON dosyasında toplar. Şablon oluşturup paylaşmak için.

String _safeName(String title) {
  final t = title.trim().isEmpty ? 'sablon' : title.trim();
  return t.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
}

/// Bir notu `.ntdl` olarak dışa aktarır (kullanıcı kayıt konumunu seçer).
Future<void> exportNtdl(WidgetRef ref, Document doc) async {
  final strokes = await ref.read(drawingRepositoryProvider).getStrokes(doc.id);
  final data = {
    'format': 'ntdl',
    'version': 1,
    'note': {
      'title': doc.title,
      'pageSize': doc.pageSize,
      'pageColor': doc.pageColor,
      'pageCount': doc.pageCount,
      'body': doc.body,
    },
    'strokes': [
      for (final s in strokes)
        {
          'page': s.page,
          'tool': s.tool,
          'color': s.color,
          'width': s.width,
          'points': s.points,
        },
    ],
  };

  final name = _safeName(doc.title);
  final bytes = Uint8List.fromList(utf8.encode(jsonEncode(data)));
  await FilePicker.saveFile(
    dialogTitle: 'Şablonu kaydet',
    fileName: '$name.ntdl',
    bytes: bytes,
  );
}

/// Bir `.ntdl` dosyasını içe aktarır: yeni not + çizimlerini oluşturup açar.
Future<void> importNtdlFromPath(WidgetRef ref, String srcPath) async {
  String raw;
  try {
    raw = await File(srcPath).readAsString();
  } catch (_) {
    return;
  }
  Map<String, dynamic> data;
  try {
    data = jsonDecode(raw) as Map<String, dynamic>;
  } catch (_) {
    return;
  }
  final format = data['format'];
  if (format != 'ntdl' && format != 'nsdl') return;

  final note = (data['note'] as Map?)?.cast<String, dynamic>() ?? {};
  final id = await ref.read(documentRepositoryProvider).insertNote(
        title: (note['title'] as String?) ?? '',
        body: (note['body'] as String?) ?? '',
        folder: 'Kişisel',
        pageSize: (note['pageSize'] as String?) ?? 'a4',
        pageColor: (note['pageColor'] as String?) ?? 'beyaz',
        pageCount: (note['pageCount'] as int?) ?? 1,
      );

  final strokes = (data['strokes'] as List?) ?? const [];
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

  ref.read(toolProvider.notifier).state = PenTool.el;
  ref.read(zoomProvider.notifier).state = 1.0;
  ref.read(navProvider.notifier).openDoc(id, isPdf: false);
}

/// Cihazdan bir `.ntdl` seçtirip içe aktarır.
Future<void> importNtdlPick(WidgetRef ref) async {
  final res = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['ntdl', 'nsdl'],
  );
  final path = res?.files.isNotEmpty == true ? res!.files.first.path : null;
  if (path == null) return;
  await importNtdlFromPath(ref, path);
}
