import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/i18n/i18n.dart';
import '../../data/data_providers.dart';
import '../editor/editor_state.dart';
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

/// Bir not gövdesindeki görsel dosya adları.
Set<String> imageNamesInBody(String body) {
  if (!isFormBody(body)) return const {};
  final form = FormDoc.tryParse(body);
  if (form == null) return const {};
  return {
    for (final b in form.blocks)
      if (b is ImageBlock && b.file.isNotEmpty) b.file,
  };
}

/// Artık hiçbir notun kullanmadığı görsel dosyalarını siler.
///
/// Bir not kalıcı silindiğinde çağrılır. Dosyalar **paylaşılabilir** olduğu
/// için (notu çoğaltmak aynı dosyaya işaret eder) körlemesine silinemez:
/// önce kalan tüm belgelerin gövdeleri taranır, yalnız hiçbirinde geçmeyen
/// dosyalar kaldırılır.
Future<void> pruneUnusedImages(
  List<String> remainingBodies, {
  Set<String> stillPlaced = const {},
}) async {
  try {
    final dir = await imagesDir();
    // Kullanımda sayılanlar: sayfaya yerleştirilmiş görseller (NoteImages) +
    // eski form-bloğu görselleri (gövdede duran ImageBlock'lar).
    final used = <String>{...stillPlaced};
    for (final body in remainingBodies) {
      used.addAll(imageNamesInBody(body));
    }
    for (final f in dir.listSync().whereType<File>()) {
      final name = f.path.split(RegExp(r'[\\/]')).last;
      if (used.contains(name)) continue;
      try {
        f.deleteSync();
      } catch (_) {
        // Silinemeyen dosya sorun değil; bir sonraki temizlikte denenir.
      }
    }
  } catch (_) {
    // Temizlik en iyi çabadır — başarısızlığı kullanıcıya yansıtmaz.
  }
}

/// Bir görsel dosyasının en-boy oranını (yükseklik ÷ genişlik) okur.
///
/// Görseli **çözmeden** yalnız başlığından ölçüyü alır (`ImageDescriptor`):
/// tam çözme 12 MP'lik bir telefon fotoğrafında ~48 MB bellek demek olurdu ve
/// burada tek ihtiyacımız oran.
Future<double?> _readAspect(File file) async {
  ui.ImmutableBuffer? buffer;
  ui.ImageDescriptor? desc;
  try {
    buffer = await ui.ImmutableBuffer.fromUint8List(await file.readAsBytes());
    desc = await ui.ImageDescriptor.encoded(buffer);
    if (desc.width == 0) return null;
    return desc.height / desc.width;
  } catch (_) {
    return null;
  } finally {
    desc?.dispose();
    buffer?.dispose();
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
  insert(name, aspect);
}
