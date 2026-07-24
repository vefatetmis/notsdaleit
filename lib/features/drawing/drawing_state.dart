import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
import '../../data/database/database.dart';
import '../shell/shell_state.dart';

/// Araçlar. `yazi` = metin yazma/biçimlendirme modu; `lasso` = çizim seçme
/// (kement); diğerleri çizim.
enum PenTool { el, yazi, kalem, fosfor, silgi, lasso }

/// Çizim şekli. `serbest` = normal elle çizim; diğerleri kalem/fosfor ile
/// başlangıç→bitiş sürükleyerek düzgün şekil çizer. Silgi her zaman serbesttir.
/// Şekiller aynı nokta dizisi olarak saklanır → şema/çizici/dışa aktarma değişmez.
enum ShapeMode { serbest, cizgi, dikdortgen, elips }

/// Seçili çizim şekli (kalem barındaki şekil düğmesinden).
final shapeModeProvider = StateProvider<ShapeMode>((ref) => ShapeMode.serbest);

/// Lasso (kement) ile seçilmiş çizimlerin id'leri. Oturumluk; araç lasso'dan
/// çıkınca ya da boşluğa kement atınca temizlenir.
final strokeSelectionProvider = StateProvider<Set<int>>((ref) => <int>{});

/// [p] noktası kapalı [poly] çokgeninin içinde mi? (ışın atma / ray casting).
/// Lasso seçiminde bir çizginin noktalarını test etmek için kullanılır.
bool pointInPolygon(Offset p, List<Offset> poly) {
  if (poly.length < 3) return false;
  var inside = false;
  for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
    final pi = poly[i];
    final pj = poly[j];
    if ((pi.dy > p.dy) != (pj.dy > p.dy) &&
        p.dx <
            (pj.dx - pi.dx) * (p.dy - pi.dy) / (pj.dy - pi.dy) + pi.dx) {
      inside = !inside;
    }
  }
  return inside;
}

/// Şekil modunda başlangıç [a] ve güncel [b] noktasından (normalize) çizilecek
/// nokta dizisini üretir. Çizgi = iki nokta; dikdörtgen = 4 köşe (kapalı);
/// elips = örneklenmiş nokta halkası.
List<Offset> buildShapePoints(ShapeMode mode, Offset a, Offset b) {
  switch (mode) {
    case ShapeMode.serbest:
    case ShapeMode.cizgi:
      return [a, b];
    case ShapeMode.dikdortgen:
      // Çizici 3+ noktalı yolları bézier ile yumuşattığı için köşeler yuvarlanır
      // (yol SolÜst'te başlayıp bittiğinden yalnız o köşe keskin kalırdı).
      // Çözüm: her köşenin hemen iki yanına çok yakın nokta koy → yumuşatmanın
      // yuvarlama yarıçapı görünmeyecek kadar küçülür, kenarlar düz kalır.
      final l = math.min(a.dx, b.dx);
      final r = math.max(a.dx, b.dx);
      final t = math.min(a.dy, b.dy);
      final bo = math.max(a.dy, b.dy);
      const eps = 0.005; // sayfa genişliğinin ~%0,5'i
      final ex = math.min(eps, (r - l) * 0.35);
      final ey = math.min(eps, (bo - t) * 0.35);
      return [
        Offset(l, t),
        Offset(l + ex, t),
        Offset(r - ex, t),
        Offset(r, t),
        Offset(r, t + ey),
        Offset(r, bo - ey),
        Offset(r, bo),
        Offset(r - ex, bo),
        Offset(l + ex, bo),
        Offset(l, bo),
        Offset(l, bo - ey),
        Offset(l, t + ey),
        Offset(l, t),
      ];
    case ShapeMode.elips:
      final cx = (a.dx + b.dx) / 2;
      final cy = (a.dy + b.dy) / 2;
      final rx = (b.dx - a.dx).abs() / 2;
      final ry = (b.dy - a.dy).abs() / 2;
      const n = 48;
      return [
        for (var i = 0; i <= n; i++)
          Offset(
            cx + rx * math.cos(2 * math.pi * i / n),
            cy + ry * math.sin(2 * math.pi * i / n),
          ),
      ];
  }
}

extension PenToolId on PenTool {
  String get id => switch (this) {
        PenTool.el => 'el',
        PenTool.yazi => 'yazi',
        PenTool.kalem => 'kalem',
        PenTool.fosfor => 'fosfor',
        PenTool.silgi => 'silgi',
        PenTool.lasso => 'lasso',
      };

  /// Çizim katmanı tek parmak dokunuşunu **yakalasın** mı? Kalem/fosfor/silgi
  /// çizer, lasso seçer — hepsinde tek parmakla sayfa kaydırma devre dışıdır.
  /// (Editör ve PDF görüntüleyici de bu bayrağa bakar.)
  bool get isPen =>
      this == PenTool.kalem ||
      this == PenTool.fosfor ||
      this == PenTool.silgi ||
      this == PenTool.lasso;
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
