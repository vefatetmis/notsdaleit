import 'package:flutter/material.dart';

import 'form_model.dart';

/// Form-not düzen/ölçüm motoru — ekran (FormPage) ve PDF export ortak kullanır.
///
/// Formlar **sanal genişlikte** dizilir (gerçek A4 oranı) ve ekrana
/// FittedBox'la oranlanır; böylece telefonda da çıktıda da aynı, gerçekçi
/// yoğunluk elde edilir. [paginateForm] blok yüksekliklerini ölçüp içerik
/// taşarken blokların **sayfa sınırını ortalamamasını** sağlar (blok sığmazsa
/// bir sonraki sayfanın başına atlar).

/// Sayfa boyutuna göre formun sanal dizgi genişliği (A4 kâğıda ~16pt gövde
/// yazısı hissi verir).
double formVirtualWidth(String? pageSize) => switch (pageSize) {
      'yatay' => 735,
      'telefon' => 390,
      _ => 520, // a4 / kare / bilinmeyen
    };

/// Sayfalar arası boşluğun sayfa genişliğine oranı (ekran + PDF aynı değeri
/// kullanır → çizim koordinatları iki tarafta da hizalı kalır).
const double kPageGapRatio = 0.05;

/// Tek satırlık form yazısının satır kutusu yüksekliği (stil çarpanı 1.3).
double fbLine(double fontSize) => fontSize * 1.3;

/// Çizgili alanlarda çizginin, yazının taban çizgisine oturması için satır
/// başına baseline ofseti. [lineH] satır yüksekliği, [fontSize] yazı boyutu.
double ruledBaseline(double fontSize, double lineH) {
  final tp = TextPainter(
    text: TextSpan(
      text: 'Ay',
      style: TextStyle(
        fontSize: fontSize,
        height: lineH / fontSize,
        fontFamily: 'InstrumentSans',
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final b = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
  return b + 2.0;
}

// ── Blok metrikleri (FormPage widget'larıyla birebir aynı sabitler) ────

const double kFbBlockGap = 14; // blok altı boşluk
const double kFbLabelTop = 6;
const double kFbLabelGap = 8; // label bloğunun altı
const double kFbAreaLineH = 30; // area satır yüksekliği (14pt yazı)
const double kFbCornellLineH = 27; // cornell satır yüksekliği (13pt yazı)

double _wrapLines(String text, double fontSize, double lineH, double width) {
  if (text.isEmpty) return 1;
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontSize: fontSize,
        height: lineH / fontSize,
        fontFamily: 'InstrumentSans',
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: width < 10 ? 10 : width);
  return (tp.height / lineH).ceilToDouble();
}

/// Bir bloğun (alt boşluğu HARİÇ) yüksekliği — sanal genişlikte.
double measureFormBlock(FormBlock b, double w, {required bool editable}) {
  switch (b) {
    case TitleBlock():
      return fbLine(22);
    case FieldsBlock():
      var h = 0.0;
      for (final f in b.fields) {
        final fh = (f.label.isNotEmpty ? fbLine(10.5) + 2 : 0) +
            6 +
            fbLine(14) +
            7 +
            1;
        if (fh > h) h = fh;
      }
      return h;
    case LabelBlock():
      return kFbLabelTop + fbLine(11);
    case ChecklistBlock():
      final rowH = 12.0 + (fbLine(14.5) > 19 ? fbLine(14.5) : 19.0);
      var h = b.items.length * rowH;
      if (editable && b.addLabel.isNotEmpty) h += 24 + fbLine(13.5);
      return h;
    case NumberedBlock():
      final rowH = 10.0 + (fbLine(14) > 22 ? fbLine(14) : 22.0);
      return b.items.length * rowH;
    case AreaBlock():
      final lines = _wrapLines(b.value, 14, kFbAreaLineH, w);
      final n = lines > b.minLines ? lines : b.minLines.toDouble();
      return n * kFbAreaLineH;
    case MoodBlock():
      return 26;
    case HoursBlock():
      return b.rows.length * 35.0;
    case WeekBlock():
      var maxItems = 0;
      for (final d in b.days) {
        if (d.items.length > maxItems) maxItems = d.items.length;
      }
      return 16 + (fbLine(12) + 6) + maxItems * 21.0;
    case CornellBlock():
      final colW = w * 16 / 25 - 24; // notlar sütunu iç genişliği (yaklaşık)
      final cueLines = _wrapLines(b.notes, 13, kFbCornellLineH, colW);
      final lines = cueLines > 12 ? cueLines : 12.0;
      final sumLines = _wrapLines(b.summary, 13, kFbCornellLineH, w - 24);
      final sLines = sumLines > 2 ? sumLines : 2.0;
      final box1 = 24 + fbLine(10) + 8 + lines * kFbCornellLineH;
      final box2 = 24 + fbLine(10) + 8 + sLines * kFbCornellLineH;
      return box1 + 12 + box2;
    case SketchBlock():
      return b.height;
  }
}

// Satırlı blokların (checklist/numaralı/saat) satır yükseklikleri — ekran ve
// PDF aynı değeri kullanır.
double get kFbCheckRowH => 12.0 + (fbLine(14.5) > 19 ? fbLine(14.5) : 19.0);
double get kFbCheckAddH => 24.0 + fbLine(13.5);
double get kFbNumRowH => 10.0 + (fbLine(14) > 22 ? fbLine(14) : 22.0);
const double kFbHourRowH = 35;

/// Sayfalanabilir en küçük birim: bir bloğun tamamı ([row] == -1) ya da
/// satırlı bloklarda tek bir satır ([row] ≥ 0; checklist'te
/// `row == items.length` → "satır ekle" düğmesi).
class FormUnit {
  const FormUnit({
    required this.block,
    required this.row,
    required this.page,
    required this.top,
    required this.spacerBefore,
  });

  final int block;
  final int row;
  final int page;
  final double top; // sayfanın içerik alanı içindeki üst konum
  final double spacerBefore; // bu birimden önce eklenecek boşluk (akışta)
}

/// Sayfalama sonucu.
class FormLayoutResult {
  FormLayoutResult({required this.units, required this.pages}) {
    for (final u in units) {
      if (u.spacerBefore > 0) _spacers['${u.block}:${u.row}'] = u.spacerBefore;
    }
  }

  final List<FormUnit> units;

  /// Toplam sayfa sayısı (en az 1).
  final int pages;

  final Map<String, double> _spacers = {};

  /// Bu blok/satırdan önce eklenecek boşluk (FormPage akışı için).
  double spacerFor(int block, int row) => _spacers['$block:$row'] ?? 0;
}

/// Blokları sayfalara yerleştirir. Satırlı bloklar (checklist, numaralı,
/// saat çizelgesi) **satır satır bölünür** — sığan satırlar sayfada kalır,
/// taşanlar sonraki sayfaya akar; diğer bloklar bütün olarak atlar.
/// [contentH] bir sayfanın içerik yüksekliği, [pageSkip] iki sayfanın içerik
/// alanları arasındaki boşluk — ikisi de sanal birimde.
FormLayoutResult paginateForm(
  FormDoc form,
  double width,
  double contentH,
  double pageSkip, {
  required bool editable,
}) {
  final units = <FormUnit>[];
  var page = 0;
  var y = 0.0; // sayfa içi konum
  var lastGap = 0.0;

  void place(int block, int row, double h, double gapAfter) {
    var spacer = 0.0;
    if (y > 0 && y + h > contentH) {
      spacer = (contentH - y) + pageSkip;
      page++;
      y = 0;
    }
    units.add(FormUnit(
        block: block, row: row, page: page, top: y, spacerBefore: spacer));
    y += h + gapAfter;
    lastGap = gapAfter;
  }

  for (var bi = 0; bi < form.blocks.length; bi++) {
    final b = form.blocks[bi];
    switch (b) {
      case ChecklistBlock():
        final hasAdd = editable && b.addLabel.isNotEmpty;
        for (var r = 0; r < b.items.length; r++) {
          final last = r == b.items.length - 1 && !hasAdd;
          place(bi, r, kFbCheckRowH, last ? kFbBlockGap : 0);
        }
        if (hasAdd) place(bi, b.items.length, kFbCheckAddH, kFbBlockGap);
      case NumberedBlock():
        for (var r = 0; r < b.items.length; r++) {
          final last = r == b.items.length - 1;
          place(bi, r, kFbNumRowH, last ? kFbBlockGap : 0);
        }
      case HoursBlock():
        for (var r = 0; r < b.rows.length; r++) {
          final last = r == b.rows.length - 1;
          place(bi, r, kFbHourRowH, last ? kFbBlockGap : 0);
        }
      default:
        place(bi, -1, measureFormBlock(b, width, editable: editable),
            b is LabelBlock ? kFbLabelGap : kFbBlockGap);
    }
  }

  // Tek bloğun kendisi sayfadan büyükse (çok uzun area) içerik akmaya devam
  // eder; sayfa sayısı toplam yüksekliği de kapsasın ki küsurat sayfa oluşmasın.
  var pages = page + 1;
  final lastOverflow = y - lastGap; // son sayfadaki içerik yüksekliği
  if (lastOverflow > contentH) {
    pages =
        page + 1 + ((lastOverflow - contentH) / (contentH + pageSkip)).ceil();
  }

  return FormLayoutResult(units: units, pages: pages);
}
