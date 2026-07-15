import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Açık olan notun Quill controller'ı. Editör kurar, araç çubuğu (Aa modu)
/// biçimlendirme uygulamak için okur.
final activeQuillControllerProvider =
    StateProvider<QuillController?>((ref) => null);

/// Kağıt (sayfa) rengi seçenekleri. Metin rengi kağıda göre belirlenir; böylece
/// yazı, uygulama teması açık/koyu olsa da her zaman okunur (siyah kağıt →
/// beyaz yazı).
class PaperStyle {
  const PaperStyle(this.id, this.label, this.background, this.text);
  final String id;
  final String label;
  final Color background; // sayfa zemini
  final Color text; // yazı rengi (okunaklı olacak şekilde)

  bool get isDark => background.computeLuminance() < 0.4;
}

const List<PaperStyle> kPaperStyles = [
  PaperStyle('beyaz', 'Beyaz', Color(0xFFFFFFFF), Color(0xFF262626)),
  PaperStyle('sari', 'Sarı', Color(0xFFFBF3CE), Color(0xFF3B3524)),
  PaperStyle('yesil', 'Yeşil', Color(0xFFE6F1E4), Color(0xFF243021)),
  PaperStyle('siyah', 'Siyah', Color(0xFF141414), Color(0xFFECECEA)),
];

PaperStyle paperStyleFor(String? id) => kPaperStyles.firstWhere(
      (p) => p.id == id,
      orElse: () => kPaperStyles.first,
    );

/// Yazı tipi boyutu seçenekleri (px). Quill 'size' özniteliği olarak uygulanır.
const List<double> kFontSizes = [12, 14, 16, 18, 22, 28, 36];

/// Varsayılan gövde yazı boyutu (öznitelik verilmeyen metin için).
const double kBaseFontSize = 16;

/// Yazı tipi seçenekleri: görünen ad → font ailesi. Android'de çözülen aileler.
const Map<String, String> kNoteFonts = {
  'Instrument Sans': 'InstrumentSans',
  'Klasik (serif)': 'serif',
  'Daktilo': 'monospace',
  'Sistem': 'sans-serif',
};
