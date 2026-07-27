import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
import '../drawing/drawing_state.dart';
import '../shell/actions.dart';
import '../shell/shell_state.dart';
import 'widget_data.dart';

/// **Ana ekran widget'ları köprüsü** (Android) — widget → uygulama yönü.
///
/// Bir widget'a dokunulunca `MainActivity` uygulamayı bir *eylem* dizesiyle
/// açar. İki durum da karşılanır:
/// - **Soğuk başlatma:** uygulama kapalıyken dokunulduysa eylem native tarafta
///   bekletilir; ilk karede `consumeLaunchAction` ile alınır.
/// - **Sıcak başlatma:** uygulama arka plandaysa eylem kanaldan gelir.
///
/// Ters yön (uygulama → widget verisi) `widget_data.dart` içindedir.

/// Widget'ın açtığı "hızlı not": şablon diyaloğu **gösterilmez**, doğrudan boş
/// bir A4 not açılır — widget'ın tüm amacı araya adım koymamak.
Future<void> _createQuickNote(WidgetRef ref, {bool drawing = false}) async {
  await createConfiguredNote(
    ref,
    title: '',
    pageSize: 'a4',
    pageColor: 'beyaz',
    body: '',
  );
  // "Çizim" kısayolu: kâğıt hemen kaleme hazır gelsin (createConfiguredNote
  // notları yazı modunda açar).
  if (drawing) {
    ref.read(toolProvider.notifier).state = PenTool.kalem;
  }
}

/// Son notlar widget'ından bir belgeyi açar.
///
/// Widget verisi bayat olabilir (not bu arada silinmiş ya da kilitlenmiş
/// olabilir); o durumda kütüphaneye düşülür. **Kilitli not açılmaz** — widget
/// akışında PIN sorulacak bir ekran yok, kilitli notlar zaten listeye hiç
/// girmiyor (bkz. `widget_data.dart`).
Future<void> _openNote(WidgetRef ref, int id) async {
  final doc = await ref.read(documentRepositoryProvider).getById(id);
  if (doc == null || doc.deletedAt != null || doc.locked) {
    ref.read(navProvider.notifier).go(AppScreen.kutuphane);
    return;
  }
  openDocument(ref, doc);
}

Future<void> _handleAction(WidgetRef ref, String action) async {
  if (action.startsWith('openNote:')) {
    final id = int.tryParse(action.substring('openNote:'.length));
    if (id != null) await _openNote(ref, id);
    return;
  }
  switch (action) {
    case 'newNote':
      await _createQuickNote(ref);
    case 'newDrawing':
      await _createQuickNote(ref, drawing: true);
    case 'search':
      ref.read(navProvider.notifier).go(AppScreen.arama);
    case 'calendar':
      ref.read(navProvider.notifier).go(AppScreen.takvim);
    case 'routines':
      ref.read(navProvider.notifier).go(AppScreen.rutinler);
    case 'library':
      ref.read(navProvider.notifier).go(AppScreen.kutuphane);
  }
}

/// Uygulama açılışında bir kez çağrılır; kanalı dinlemeye başlar ve bekleyen
/// eylem varsa uygular.
void initHomeWidgetBridge(WidgetRef ref) {
  widgetChannel.setMethodCallHandler((call) async {
    if (call.method == 'launchAction') {
      final action = call.arguments;
      if (action is String) await _handleAction(ref, action);
    }
  });

  // Soğuk başlatmada native tarafta bekleyen eylem.
  widgetChannel.invokeMethod<String>('consumeLaunchAction').then((action) {
    if (action != null && action.isNotEmpty) _handleAction(ref, action);
  }).catchError((_) {
    // Kanal yoksa (ör. başka platform) sessizce geç.
    return null;
  });
}
