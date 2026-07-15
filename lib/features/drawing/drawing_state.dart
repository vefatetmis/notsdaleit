import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
import '../../data/database/database.dart';
import '../shell/shell_state.dart';

/// Araçlar. `yazi` = metin yazma/biçimlendirme modu; diğerleri çizim.
enum PenTool { el, yazi, kalem, fosfor, silgi }

extension PenToolId on PenTool {
  String get id => switch (this) {
        PenTool.el => 'el',
        PenTool.yazi => 'yazi',
        PenTool.kalem => 'kalem',
        PenTool.fosfor => 'fosfor',
        PenTool.silgi => 'silgi',
      };

  bool get isPen =>
      this == PenTool.kalem || this == PenTool.fosfor || this == PenTool.silgi;
}

/// Tasarımdaki kalınlık taban değerleri (ince / orta / kalın).
const List<double> kStrokeSizes = [2.5, 5, 9];

/// Seçili araç.
final toolProvider = StateProvider<PenTool>((ref) => PenTool.el);

/// Seçili mürekkep rengi (0..3). Son yuva (index 3) "rengarenk" → özel renk.
final inkIndexProvider = StateProvider<int>((ref) => 0);

/// "Rengarenk" (son) yuva seçildiğinde kullanılan, paletten seçilen özel renk.
final customInkColorProvider =
    StateProvider<Color>((ref) => const Color(0xFF9C27B0));

/// Kalem araç çubuğunda görünen 3 sabit renk (kullanıcı ayarlardan seçer,
/// kalıcı). Son (4.) yuva her zaman "rengarenk"tir (bkz. [customInkColorProvider]).
class PenPaletteNotifier extends Notifier<List<Color>> {
  static const _key = 'penPalette';
  static const List<Color> _defaults = [
    Color(0xFF262626),
    Color(0xFF4A6CF7),
    Color(0xFFE0533D),
  ];

  @override
  List<Color> build() {
    final raw = ref.read(sharedPrefsProvider).getStringList(_key);
    if (raw == null || raw.length != 3) return _defaults;
    try {
      return [for (final s in raw) Color(int.parse(s))];
    } catch (_) {
      return _defaults;
    }
  }

  void setColor(int index, Color c) {
    if (index < 0 || index >= state.length) return;
    final next = [...state]..[index] = c;
    state = next;
    ref.read(sharedPrefsProvider).setStringList(
          _key,
          [for (final col in next) col.toARGB32().toString()],
        );
  }
}

final penPaletteProvider =
    NotifierProvider<PenPaletteNotifier, List<Color>>(PenPaletteNotifier.new);

/// Bir mürekkep yuvası için gerçek rengi verir: [index] palette dışındaysa
/// (son "rengarenk" yuva) özel rengi kullanır.
Color inkColorFor(List<Color> palette, int index, Color custom) {
  if (index >= palette.length) return custom;
  return palette[index];
}

/// Seçili kalınlık (0..2).
final sizeIndexProvider = StateProvider<int>((ref) => 1);

/// PDF yakınlaştırma çarpanı.
final zoomProvider = StateProvider<double>((ref) => 1.0);

/// Aktif belgenin tüm çizimleri (tüm sayfalar) — canlı akış.
final activeStrokesProvider = StreamProvider<List<Stroke>>((ref) {
  final id = ref.watch(navProvider).activeDocId;
  if (id == null) return Stream.value(const <Stroke>[]);
  return ref.watch(drawingRepositoryProvider).watchStrokes(id);
});
