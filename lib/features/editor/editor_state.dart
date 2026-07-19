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

/// Sayfa yönü/boyutu seçeneği. [aspect] = yükseklik ÷ genişlik (editör ve PDF
/// export sayfa yüksekliğini bu orandan hesaplar). Yeni not diyaloğunda seçilir.
class PageSizeOption {
  const PageSizeOption(this.id, this.tr, this.en, this.icon, this.aspect);
  final String id;
  final String tr;
  final String en;
  final IconData icon;
  final double aspect;
}

const List<PageSizeOption> kPageSizes = [
  PageSizeOption('a4', 'A4 dikey', 'A4 portrait',
      Icons.description_outlined, 1.414),
  PageSizeOption('yatay', 'A4 yatay', 'A4 landscape',
      Icons.crop_landscape_outlined, 0.7072),
  PageSizeOption('kare', 'Kare', 'Square', Icons.crop_square_outlined, 1.0),
  PageSizeOption('telefon', 'Telefon', 'Phone',
      Icons.stay_current_portrait_outlined, 2.1667),
];

/// Bir sayfa boyutu id'sinin en/boy oranını (yükseklik ÷ genişlik) döndürür.
/// Bilinmeyen/eski değerler ('serbest' dâhil) A4 dikey kabul edilir.
double aspectForPageSize(String? id) {
  for (final p in kPageSizes) {
    if (p.id == id) return p.aspect;
  }
  return 1.414;
}

PageSizeOption pageSizeOptionFor(String? id) => kPageSizes.firstWhere(
      (p) => p.id == id,
      orElse: () => kPageSizes.first,
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
