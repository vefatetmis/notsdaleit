import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shell/actions.dart';

/// **Ana ekran widget'ı köprüsü** (Android).
///
/// Widget'a dokunulunca `MainActivity` uygulamayı `newNote` eylemiyle açar.
/// Burada iki durum da karşılanır:
/// - **Soğuk başlatma:** uygulama kapalıyken dokunulduysa eylem native tarafta
///   bekletilir; ilk karede `consumeLaunchAction` ile alınır.
/// - **Sıcak başlatma:** uygulama arka plandaysa eylem kanaldan gelir.
///
/// **Neden `home_widget` paketi yok:** widget durağan; tek ihtiyacı bir
/// PendingIntent ve bu küçük kanal. Paket eklemek yeni bir Kotlin sürüm
/// bağımlılığı demekti (eklentiler 1.9.25'e sabit, bkz. CLAUDE.md).
const _channel = MethodChannel('notsdaleit/widget');

/// Widget'ın açtığı "hızlı not": şablon diyaloğu **gösterilmez**, doğrudan boş
/// bir A4 not açılır — widget'ın tüm amacı araya adım koymamak.
Future<void> _createQuickNote(WidgetRef ref) {
  return createConfiguredNote(
    ref,
    title: '',
    pageSize: 'a4',
    pageColor: 'beyaz',
    body: '',
  );
}

/// Uygulama açılışında bir kez çağrılır; kanalı dinlemeye başlar ve bekleyen
/// eylem varsa uygular.
void initHomeWidgetBridge(WidgetRef ref) {
  _channel.setMethodCallHandler((call) async {
    if (call.method == 'launchAction' && call.arguments == 'newNote') {
      await _createQuickNote(ref);
    }
  });

  // Soğuk başlatmada native tarafta bekleyen eylem.
  _channel.invokeMethod<String>('consumeLaunchAction').then((action) {
    if (action == 'newNote') _createQuickNote(ref);
  }).catchError((_) {
    // Kanal yoksa (ör. başka platform) sessizce geç.
    return null;
  });
}
