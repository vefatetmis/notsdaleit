import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/i18n/i18n.dart';
import '../../data/data_providers.dart';
import '../editor/editor_state.dart';
import 'form_layout.dart';
import 'form_model.dart';

/// Nota görsel ekleme akışı.
///
/// **Neden `file_picker`?** Projede zaten var ve galeriden görsel seçmeye
/// yetiyor. `image_picker` (kameradan çekme) yeni bir bağımlılık demek ve
/// eklentilerin Kotlin sürümü 1.9.25'e sabitlenmiş durumda (bkz. CLAUDE.md) —
/// kamerayı ayrı bir adımda, riski ölçerek eklemek daha doğru.
///
/// Seçilen dosya **uygulama klasörüne kopyalanır**: galerideki asıl dosya
/// silinse/taşınsa bile not bozulmasın.

/// Görsellerin tutulduğu klasör (`<appDocs>/images`).
Future<Directory> imagesDir() async {
  final base = await getApplicationDocumentsDirectory();
  final dir = Directory('${base.path}/images');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  return dir;
}

/// Kayıtlı bir görselin tam yolu (model yalnız dosya adını tutar — tam yol
/// cihazdan cihaza değişir).
File imageFileFor(String dirPath, String name) => File('$dirPath/$name');

/// Görselin sayfaya sığması için en-boy oranını sınırlar. Oran modelde tutulur
/// çünkü sayfalama ölçümü senkron olmak zorunda (dosyayı açamaz).
double clampImageAspect(double aspect, String? pageSize) {
  final m = formMetrics(pageSize);
  final maxAspect = (m.contentH * 0.9) / m.virtualW;
  if (aspect <= 0 || !aspect.isFinite) return 0.75;
  return aspect > maxAspect ? maxAspect : aspect;
}

/// Bir görsel dosyasının en-boy oranını (yükseklik ÷ genişlik) okur.
Future<double?> _readAspect(File file) async {
  try {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final img = frame.image;
    final a = img.height / img.width;
    img.dispose();
    codec.dispose();
    return a;
  } catch (_) {
    return null;
  }
}

/// "Görsel ekle": cihazdan bir görsel seçtirir, uygulama klasörüne kopyalar ve
/// editörün kancasını ([imageInserterProvider]) çağırır. Görsel notun **sonuna**
/// eklenir (tablo gibi — araya girmek sonraki blokların index'ini kaydırıp
/// alan biçimlerini bozardı).
Future<void> insertImageIntoNote(BuildContext context, WidgetRef ref) async {
  final insert = ref.read(imageInserterProvider);
  if (insert == null) return;
  final doc = ref.read(activeDocumentProvider);
  if (doc == null) return;

  void toast(String tr, String en) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(context.t(tr, en)),
      ));
  }

  // Serbest (Quill) not tabloda olduğu gibi forma dönüşür → önceden söyle.
  if (!isFormBody(doc.body)) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.t('Görsel ekle', 'Add image')),
        content: Text(ctx.t(
          'Bu not görsel eklenince form notuna dönüşür: mevcut yazın çizgili '
              'bir metin alanına taşınır, kalın/italik gibi biçimler düz metne '
              'döner. Çizimler olduğu gibi kalır.',
          'Adding an image turns this note into a form note: your current text '
              'moves into a ruled text area and formatting like bold/italic '
              'becomes plain text. Drawings are kept as they are.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.t('Vazgeç', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.t('Devam', 'Continue')),
          ),
        ],
      ),
    );
    if (ok != true) return;
  }

  final res = await FilePicker.pickFiles(type: FileType.image);
  final path = res?.files.isNotEmpty == true ? res!.files.first.path : null;
  if (path == null) return;

  final src = File(path);
  if (!src.existsSync()) {
    toast('Görsel okunamadı', 'Could not read the image');
    return;
  }

  // Kopyala (galerideki asıl dosya silinse bile not bozulmasın).
  String name;
  try {
    final dir = await imagesDir();
    final ext = path.contains('.') ? path.split('.').last.toLowerCase() : 'jpg';
    name = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    await src.copy('${dir.path}/$name');
  } catch (_) {
    toast('Görsel kaydedilemedi', 'Could not save the image');
    return;
  }

  final dir = await imagesDir();
  final aspect = await _readAspect(imageFileFor(dir.path, name)) ?? 0.75;
  insert(name, clampImageAspect(aspect, doc.pageSize));
}
