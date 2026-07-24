import 'package:flutter/material.dart';

/// Uygulamanın renk tokenları. Açık ve koyu için ayrı setler. Widget'lar
/// `Theme.of(context).extension<NdColors>()!` ile erişir.
///
/// **Palet: sıcak bej + koyu mavi.** İlk tasarım (notdaleit.dc.html) saf
/// beyaz yüzey + siyah vurgu kullanıyordu; kullanıcı geri bildirimi "çok
/// parlak, çok soğuk" olduğu için zemin/kart sıcak bej-fildişine, vurgu da
/// maviye çevrildi. Vurgu tonu kullanıcının verdiği `#295DB4` (ilk denenen
/// `#3F6E9E` "soluk" bulundu). Not **kâğıdının** beyazı buraya dâhil DEĞİL — o
/// `editor_state.kPaperStyles`'ta ve olduğu gibi kalmalı (PDF çıktısıyla
/// uyuşması için). Kalem renkleri ([inks]) de ayrı kalır.
@immutable
class NdColors extends ThemeExtension<NdColors> {
  const NdColors({
    required this.bg,
    required this.card,
    required this.sidebar,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.text2,
    required this.bar,
    required this.bar2,
    required this.hover,
    required this.accent,
    required this.accentFg,
    required this.accentSoft,
    required this.inks,
  });

  final Color bg; // arka plan
  final Color card; // kart yüzeyi
  final Color sidebar; // yan panel
  final Color border; // ince kenarlık
  final Color borderStrong; // belirgin kenarlık
  final Color text; // ana metin
  final Color text2; // soluk metin
  final Color bar; // iskelet çubuk (koyu)
  final Color bar2; // iskelet çubuk (açık)
  final Color hover; // hover zemini
  final Color accent; // vurgu (buton) zemini — denim mavi
  final Color accentFg; // vurgu üzeri metin
  final Color accentSoft; // vurgunun soluk zemini (seçili öğe, çip)
  final List<Color> inks; // kalem renkleri

  static const light = NdColors(
    bg: Color(0xFFF6F2EA),
    card: Color(0xFFFFFCF6),
    sidebar: Color(0xFFEFE9DE),
    border: Color(0xFFE7E0D3),
    borderStrong: Color(0xFFDBD2C1),
    text: Color(0xFF2B2723),
    text2: Color(0xFF8B8175),
    bar: Color(0xFFCFC6B5),
    bar2: Color(0xFFE6DFD2),
    hover: Color(0xFFEDE6D8),
    accent: Color(0xFF295DB4),
    accentFg: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFDFE8F7),
    inks: [
      Color(0xFF262626),
      Color(0xFF4A6CF7),
      Color(0xFFE0533D),
      Color(0xFFF0B429),
    ],
  );

  static const dark = NdColors(
    bg: Color(0xFF16140F),
    card: Color(0xFF1E1B16),
    sidebar: Color(0xFF1A1712),
    border: Color(0xFF2C2820),
    borderStrong: Color(0xFF3A3529),
    text: Color(0xFFECE7DE),
    text2: Color(0xFF9A9184),
    bar: Color(0xFF4A453A),
    bar2: Color(0xFF2A261E),
    hover: Color(0xFF232019),
    accent: Color(0xFF6E9FE8),
    accentFg: Color(0xFF0B162B),
    accentSoft: Color(0xFF1B2740),
    inks: [
      Color(0xFFECECEA),
      Color(0xFF4A6CF7),
      Color(0xFFE0533D),
      Color(0xFFF0B429),
    ],
  );

  /// Tasarımdaki yumuşak gölge (--nd-sh).
  List<BoxShadow> get shadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.14),
          blurRadius: 36,
          spreadRadius: -14,
          offset: const Offset(0, 14),
        ),
      ];

  @override
  NdColors copyWith({
    Color? bg,
    Color? card,
    Color? sidebar,
    Color? border,
    Color? borderStrong,
    Color? text,
    Color? text2,
    Color? bar,
    Color? bar2,
    Color? hover,
    Color? accent,
    Color? accentFg,
    Color? accentSoft,
    List<Color>? inks,
  }) {
    return NdColors(
      bg: bg ?? this.bg,
      card: card ?? this.card,
      sidebar: sidebar ?? this.sidebar,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      text: text ?? this.text,
      text2: text2 ?? this.text2,
      bar: bar ?? this.bar,
      bar2: bar2 ?? this.bar2,
      hover: hover ?? this.hover,
      accent: accent ?? this.accent,
      accentFg: accentFg ?? this.accentFg,
      accentSoft: accentSoft ?? this.accentSoft,
      inks: inks ?? this.inks,
    );
  }

  @override
  NdColors lerp(ThemeExtension<NdColors>? other, double t) {
    if (other is! NdColors) return this;
    return NdColors(
      bg: Color.lerp(bg, other.bg, t)!,
      card: Color.lerp(card, other.card, t)!,
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      text: Color.lerp(text, other.text, t)!,
      text2: Color.lerp(text2, other.text2, t)!,
      bar: Color.lerp(bar, other.bar, t)!,
      bar2: Color.lerp(bar2, other.bar2, t)!,
      hover: Color.lerp(hover, other.hover, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentFg: Color.lerp(accentFg, other.accentFg, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      inks: t < 0.5 ? inks : other.inks,
    );
  }
}

/// Kısayol: `context.nd` ile token setine eriş.
extension NdColorsX on BuildContext {
  NdColors get nd => Theme.of(this).extension<NdColors>()!;
}
