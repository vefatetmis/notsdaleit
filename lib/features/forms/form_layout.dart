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

/// Sayfalama sonucu.
class FormLayoutResult {
  FormLayoutResult({
    required this.spacerBefore,
    required this.pageOf,
    required this.topInPage,
    required this.pages,
  });

  /// Her blok öncesi eklenecek dikey boşluk (sayfa atlaması; çoğunlukla 0).
  final List<double> spacerBefore;

  /// Her bloğun düştüğü sayfa (0 tabanlı).
  final List<int> pageOf;

  /// Bloğun kendi sayfasının içerik alanı içindeki üst konumu.
  final List<double> topInPage;

  /// Toplam sayfa sayısı (en az 1).
  final int pages;
}

/// Blokları sayfalara yerleştirir. [contentH] bir sayfanın içerik yüksekliği,
/// [pageSkip] iki sayfanın içerik alanları arasındaki boşluk (alt kenar +
/// sayfa arası + üst kenar) — ikisi de sanal birimde.
FormLayoutResult paginateForm(
  FormDoc form,
  double width,
  double contentH,
  double pageSkip, {
  required bool editable,
}) {
  final spacer = <double>[];
  final pageOf = <int>[];
  final topInPage = <double>[];
  var page = 0;
  var y = 0.0; // sayfa içi konum
  var lastGap = 0.0;

  for (final b in form.blocks) {
    final h = measureFormBlock(b, width, editable: editable);
    final gapAfter = b is LabelBlock ? kFbLabelGap : kFbBlockGap;
    if (y > 0 && y + h > contentH) {
      // Blok bu sayfaya sığmıyor → sonraki sayfanın başına atla.
      spacer.add((contentH - y) + pageSkip);
      page++;
      y = 0;
    } else {
      spacer.add(0);
    }
    pageOf.add(page);
    topInPage.add(y);
    y += h + gapAfter;
    lastGap = gapAfter;
  }

  // Tek bloğun kendisi sayfadan büyükse (çok uzun area) içerik akmaya devam
  // eder; sayfa sayısı toplam yüksekliği de kapsasın ki küsurat sayfa oluşmasın.
  var pages = page + 1;
  final lastOverflow = y - lastGap; // son sayfadaki içerik yüksekliği
  if (lastOverflow > contentH) {
    pages = page + 1 + ((lastOverflow - contentH) / (contentH + pageSkip)).ceil();
  }

  return FormLayoutResult(
    spacerBefore: spacer,
    pageOf: pageOf,
    topInPage: topInPage,
    pages: pages,
  );
}
