import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Açık olan notun Quill controller'ı. Editör kurar, araç çubuğu (Aa modu)
/// biçimlendirme uygulamak için okur.
final activeQuillControllerProvider =
    StateProvider<QuillController?>((ref) => null);

/// Form notunda o an **odaklanmış metin alanı**. Form alanları Quill değil düz
/// `TextField` olduğundan biçimlendirme alan bazlıdır: araç çubuğu bu nesneyi
/// okuyup alanın tamamına kalın/italik/altı çizili uygular. `FormPage` odak
/// değiştikçe günceller, odak kaybında `null` yapar.
class ActiveFormField {
  const ActiveFormField({required this.flags, required this.toggle});

  /// Alanın mevcut biçim bayrakları ('b', 'i', 'u' — ör. 'bu').
  final String flags;

  /// Bir bayrağı açar/kapatır; `FormPage` uygular ve notu kaydeder.
  final void Function(String flag) toggle;
}

final activeFormFieldProvider = StateProvider<ActiveFormField?>((ref) => null);

/// Kağıt (sayfa) rengi seçenekleri. Metin rengi kağıda göre belirlenir; böylece
/// yazı, uygulama teması açık/koyu olsa da her zaman okunur (siyah kağıt →
/// beyaz yazı).
class PaperStyle {
  const PaperStyle(
    this.id,
    this.label,
    this.background,
    this.text, {
    required this.line,
    required this.muted,
    required this.faint,
  });
  final String id;
  final String label;
  final Color background; // sayfa zemini
  final Color text; // yazı rengi (okunaklı olacak şekilde)
  final Color line; // çizgili/kareli/noktalı arka plan + ayraç çizgisi rengi
  final Color muted; // soluk etiket/ipucu rengi (kağıda göre)
  final Color faint; // çok hafif dolgu (chip/kutu zemini)

  bool get isDark => background.computeLuminance() < 0.4;
}

// Renkler Claude Design "Not Şablonları" handoff'undaki THEMES ile birebir.
const List<PaperStyle> kPaperStyles = [
  PaperStyle('beyaz', 'Beyaz', Color(0xFFFFFFFF), Color(0xFF1E1E1C),
      line: Color(0xFFE7E5DF), muted: Color(0xFFA6A49D), faint: Color(0xFFF5F3EE)),
  PaperStyle('sari', 'Sarı', Color(0xFFF6ECCE), Color(0xFF3B3524),
      line: Color(0xFFE6D6A2), muted: Color(0xFFB0A074), faint: Color(0xFFF1E3BA)),
  PaperStyle('yesil', 'Yeşil', Color(0xFFE8F0E6), Color(0xFF26332A),
      line: Color(0xFFCDDFCA), muted: Color(0xFF8BA58F), faint: Color(0xFFDCE9D9)),
  PaperStyle('siyah', 'Siyah', Color(0xFF1B1C1E), Color(0xFFF0EFEC),
      line: Color(0xFF37383B), muted: Color(0xFF85857F), faint: Color(0xFF262729)),
];

/// Sayfa arka planı (kâğıt deseni). Editör ve PDF export sayfa arkasına çizer.
class PageBgOption {
  const PageBgOption(this.id, this.tr, this.en, this.icon);
  final String id;
  final String tr;
  final String en;
  final IconData icon;
}

const List<PageBgOption> kPageBackgrounds = [
  PageBgOption('duz', 'Düz', 'Plain', Icons.crop_portrait_outlined),
  PageBgOption('cizgili', 'Çizgili', 'Lined', Icons.notes_outlined),
  PageBgOption('kareli', 'Kareli', 'Grid', Icons.grid_on_outlined),
  PageBgOption('noktali', 'Noktalı', 'Dotted', Icons.more_horiz_rounded),
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

/// Sayfa arka plan desenini bir canvas'a çizer — editör ve PDF export ortak
/// kullanır (böylece ekranda ne görünüyorsa PDF'te de o çıkar). Aralıklar sayfa
/// genişliğine oranlıdır → her boyutta tutarlı yoğunluk.
void paintPageBackground(Canvas canvas, Size size, String type, Color lineColor) {
  if (type == 'duz' || size.width <= 0 || size.height <= 0) return;
  final lineGap = size.width * 0.062; // çizgi aralığı
  final cell = size.width * 0.05; // kare / nokta aralığı
  final paint = Paint()
    ..color = lineColor
    ..strokeWidth = 1
    ..isAntiAlias = true;
  if (type == 'cizgili') {
    for (var y = lineGap; y < size.height; y += lineGap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  } else if (type == 'kareli') {
    for (var y = cell; y < size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (var x = cell; x < size.width; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  } else if (type == 'noktali') {
    final dot = Paint()
      ..color = lineColor
      ..isAntiAlias = true;
    final r = (size.width * 0.0022).clamp(0.8, 2.2);
    for (var y = cell; y < size.height; y += cell) {
      for (var x = cell; x < size.width; x += cell) {
        canvas.drawCircle(Offset(x, y), r, dot);
      }
    }
  }
}

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
