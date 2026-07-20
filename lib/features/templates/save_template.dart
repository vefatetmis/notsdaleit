import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/i18n.dart';
import '../../data/data_providers.dart';
import '../../data/database/database.dart';

/// Mevcut notu (metin gövdesi + sayfa boyutu/rengi + çizimler) yerel
/// "Şablonlarım" listesine kaydeder. Yeni not diyaloğunun "Şablonlarım"
/// sekmesinde görünür. Kullanıcıya şablon adını sorar (not başlığıyla dolu gelir).
Future<void> saveNoteAsTemplate(
  BuildContext context,
  WidgetRef ref,
  Document doc,
) async {
  final controller = TextEditingController(text: doc.title);
  final name = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.t('Şablon olarak kaydet', 'Save as template')),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: context.t('Şablon adı', 'Template name'),
        ),
        onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.t('Vazgeç', 'Cancel')),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(controller.text.trim()),
          child: Text(context.t('Kaydet', 'Save')),
        ),
      ],
    ),
  );
  controller.dispose();
  if (name == null) return; // iptal

  final strokes = await ref.read(drawingRepositoryProvider).getStrokes(doc.id);
  final strokesJson = jsonEncode([
    for (final s in strokes)
      {
        'page': s.page,
        'tool': s.tool,
        'color': s.color,
        'width': s.width,
        'points': s.points,
      },
  ]);

  await ref.read(templateRepositoryProvider).add(
        title: name,
        pageSize: doc.pageSize,
        pageColor: doc.pageColor,
        pageBackground: doc.pageBackground,
        body: doc.body,
        strokes: strokesJson,
      );

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(context.t('Şablon kaydedildi', 'Template saved')),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
