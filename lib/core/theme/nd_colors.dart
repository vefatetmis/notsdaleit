import 'package:flutter/material.dart';

/// Tasarımdaki (notdaleit.dc.html) renk tokenları. Açık ve koyu için ayrı
/// setler. Widget'lar `Theme.of(context).extension<NdColors>()!` ile erişir.
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
  final Color accent; // vurgu (buton) zemini
  final Color accentFg; // vurgu üzeri metin
  final List<Color> inks; // kalem renkleri

  static const light = NdColors(
    bg: Color(0xFFFAFAFA),
    card: Color(0xFFFFFFFF),
    sidebar: Color(0xFFF5F5F3),
    border: Color(0xFFEBEBE9),
    borderStrong: Color(0xFFE1E1DF),
    text: Color(0xFF262626),
    text2: Color(0xFF8F8F8C),
    bar: Color(0xFFCFCFCC),
    bar2: Color(0xFFE7E7E4),
    hover: Color(0xFFF0F0EE),
    accent: Color(0xFF262626),
    accentFg: Color(0xFFFFFFFF),
    inks: [
      Color(0xFF262626),
      Color(0xFF4A6CF7),
      Color(0xFFE0533D),
      Color(0xFFF0B429),
    ],
  );

  static const dark = NdColors(
    bg: Color(0xFF141414),
    card: Color(0xFF1A1A1A),
    sidebar: Color(0xFF171717),
    border: Color(0xFF262626),
    borderStrong: Color(0xFF333333),
    text: Color(0xFFECECEA),
    text2: Color(0xFF8F8F8C),
    bar: Color(0xFF4A4A48),
    bar2: Color(0xFF262626),
    hover: Color(0xFF202020),
    accent: Color(0xFFECECEA),
    accentFg: Color(0xFF191918),
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
      inks: t < 0.5 ? inks : other.inks,
    );
  }
}

/// Kısayol: `context.nd` ile token setine eriş.
extension NdColorsX on BuildContext {
  NdColors get nd => Theme.of(this).extension<NdColors>()!;
}
