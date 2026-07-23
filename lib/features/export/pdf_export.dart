import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/i18n/i18n.dart';
import '../../data/data_providers.dart';
import '../../data/database/database.dart';
import '../drawing/drawing_state.dart';
import '../drawing/stroke_painter.dart';
import '../editor/editor_state.dart';
import '../editor/table_embed.dart';
import '../forms/form_layout.dart';
import '../forms/form_model.dart';

String _safeName(String title) {
  final t = title.trim().isEmpty ? 'not' : title.trim();
  return t.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
}

/// PDF çıktısında kâğıdın nasıl görüneceği (dışa aktarırken sorulur; not
/// değişmez). white = beyaz zemin/koyu mürekkep · tint = kâğıt renginin açık
/// tonu · full = ekrandaki kâğıt rengi birebir.
enum PdfPaper { white, tint, full }

/// PDF çizim renkleri (mürekkep + çizgi + soluk + hafif + zemin). Seçilen
/// [PdfPaper] moduna göre kurulur; tüm çizim fonksiyonları bunu kullanır.
class _PdfPalette {
  const _PdfPalette({
    required this.background,
    required this.ink,
    required this.line,
    required this.muted,
    required this.faint,
  });
  final Color background;
  final Color ink;
  final Color line;
  final Color muted;
  final Color faint;
}

const _PdfPalette _whitePalette = _PdfPalette(
  background: Color(0xFFFFFFFF),
  ink: Color(0xFF262626),
  line: Color(0xFFE7E5DF),
  muted: Color(0xFFA6A49D),
  faint: Color(0xFFF5F3EE),
);

_PdfPalette _pdfPalette(String pageColor, PdfPaper mode) {
  final paper = paperStyleFor(pageColor);
  switch (mode) {
    case PdfPaper.white:
      return _whitePalette;
    case PdfPaper.full:
      return _PdfPalette(
        background: paper.background,
        ink: paper.text,
        line: paper.line,
        muted: paper.muted,
        faint: paper.faint,
      );
    case PdfPaper.tint:
      // Koyu kâğıdın "hafif ton"u anlamsız → beyaza düş.
      if (paper.isDark) return _whitePalette;
      final bg = Color.lerp(
          const Color(0xFFFFFFFF), paper.background, 0.55)!;
      return _PdfPalette(
        background: bg,
        ink: const Color(0xFF262626),
        line: paper.line,
        muted: paper.muted,
        faint: paper.faint,
      );
  }
}

/// "PDF olarak paylaş" akışı: renkli kâğıtlı notlarda önce kâğıt rengini sorar
/// (not değişmez), sonra seçime göre dışa aktarır. Beyaz kâğıt / PDF belgesinde
/// sormadan aktarır.
Future<void> sharePdfWithPaperPrompt(
  BuildContext context,
  WidgetRef ref,
  Document doc,
) async {
  if (doc.type == 'pdf' || doc.pageColor == 'beyaz') {
    await exportDocumentAsPdf(ref, doc);
    return;
  }

  final choice = await _askPaper(
      context, doc, context.t('PDF kâğıt rengi', 'PDF paper color'));
  if (choice == null) return;
  await exportDocumentAsPdf(ref, doc, paper: choice);
}

/// Renkli kâğıtlı bir not dışa aktarılırken kâğıdın çıktıda nasıl görüneceğini
/// sorar. PDF ve PNG akışları ortak kullanır. Vazgeçilirse null döner.
Future<PdfPaper?> _askPaper(
    BuildContext context, Document doc, String dialogTitle) {
  final paper = paperStyleFor(doc.pageColor);
  final tintBg = paper.isDark
      ? const Color(0xFFFFFFFF)
      : Color.lerp(const Color(0xFFFFFFFF), paper.background, 0.55)!;

  return showDialog<PdfPaper>(
    context: context,
    builder: (context) {
      Widget option(PdfPaper mode, Color swatch, String title, String sub) {
        return InkWell(
          onTap: () => Navigator.of(context).pop(mode),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: swatch,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: const Color(0x33000000)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w600)),
                      Text(sub,
                          style: const TextStyle(fontSize: 12.5, height: 1.3)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return AlertDialog(
        title: Text(dialogTitle),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            option(
                PdfPaper.white,
                const Color(0xFFFFFFFF),
                context.t('Beyaz', 'White'),
                context.t('Beyaz zemin — baskı dostu', 'White page — print-friendly')),
            option(
                PdfPaper.tint,
                tintBg,
                context.t('Hafif ton', 'Light tint'),
                context.t('Kâğıt renginin açık tonu', 'A soft tint of the paper color')),
            option(
                PdfPaper.full,
                paper.background,
                context.t('Tam renk', 'Full color'),
                context.t('Ekrandaki kâğıt rengi birebir', 'Exactly as on screen')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.t('Vazgeç', 'Cancel')),
          ),
        ],
      );
    },
  );
}

/// Bir belgeyi PDF olarak dışa aktarır ve paylaşım sayfasını açar. [paper]
/// kâğıdın çıktıdaki görünümünü belirler (not içeriği/kaydı değişmez).
/// - PDF belgesi → özgün dosya paylaşılır.
/// - Not → biçimli metin / form blokları + çizimler.
Future<void> exportDocumentAsPdf(
  WidgetRef ref,
  Document doc, {
  PdfPaper paper = PdfPaper.white,
}) async {
  final filename = '${_safeName(doc.title)}.pdf';
  final pal = _pdfPalette(doc.pageColor, paper);

  if (doc.type == 'pdf') {
    final path = doc.filePath;
    if (path != null && File(path).existsSync()) {
      final bytes = await File(path).readAsBytes();
      await Printing.sharePdf(bytes: bytes, filename: filename);
      return;
    }
  }

  final rows = await ref.read(drawingRepositoryProvider).getStrokes(doc.id);
  final aspect = aspectForPageSize(doc.pageSize);
  var pageCount = doc.pageCount ?? 1;
  const w = 1240.0;
  final h = w * aspect;
  // Sayfa boyutuna uygun PDF formatı (yükseklik = genişlik × aspect).
  final format = switch (doc.pageSize) {
    'kare' => PdfPageFormat(PdfPageFormat.a4.width, PdfPageFormat.a4.width),
    'yatay' => PdfPageFormat(PdfPageFormat.a4.height, PdfPageFormat.a4.width),
    'telefon' =>
      PdfPageFormat(PdfPageFormat.a4.width, PdfPageFormat.a4.width * aspect),
    _ => PdfPageFormat.a4,
  };

  // Form-not: ekranla aynı sanal metriklerle sayfalanır (bloklar aynı
  // sayfalara düşer).
  FormDoc? form;
  FormLayoutResult? formLayout;
  var formScale = 1.0;
  if (isFormBody(doc.body)) {
    form = FormDoc.tryParse(doc.body);
    if (form != null) {
      final m = formMetrics(doc.pageSize);
      formScale = w / m.virtualPageW;
      // Export tüm içeriği tam sayfalar (ekrandaki manuel sayfa sınırından
      // bağımsız) → çıktıda hiçbir şey kırpılmaz.
      formLayout = paginateForm(form, m.virtualW, m.contentH, m.pageSkip,
          editable: false);
      if (formLayout.pages > pageCount) pageCount = formLayout.pages;
    }
  }

  // Çizimler ekranda sayfalar + aralıklardan oluşan sürekli bir düzlemde
  // durur; PDF'te her sayfa kendi dilimini kaydırılmış çizimle alır.
  final allStrokes = [for (final s in rows) PenStroke.fromRow(s)];

  final pdf = pw.Document();
  for (var i = 0; i < pageCount; i++) {
    final imageBytes = await _renderPageImage(
      w,
      h,
      allStrokes,
      // Metin (biçimli) yalnızca ilk sayfaya çizilir; form her sayfada
      // kendi bloklarını çizer.
      body: form == null && i == 0 ? doc.body : null,
      background: doc.pageBackground,
      pal: pal,
      form: form,
      formLayout: formLayout,
      formPage: i,
      formScale: formScale,
      strokeOffsetY: i * (aspect + kPageGapRatio) * w,
    );
    final memImage = pw.MemoryImage(imageBytes);
    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (ctx) => pw.FullPage(
          ignoreMargins: true,
          child: pw.Image(memImage, fit: pw.BoxFit.fill),
        ),
      ),
    );
  }

  await Printing.sharePdf(bytes: await pdf.save(), filename: filename);
}

/// "Görüntü olarak paylaş" akışı: renkli kâğıtlı notlarda önce kâğıt rengini
/// sorar (not değişmez), sonra PNG olarak dışa aktarır. Beyaz kâğıtta sormaz.
Future<void> sharePngWithPaperPrompt(
  BuildContext context,
  WidgetRef ref,
  Document doc,
) async {
  if (doc.pageColor == 'beyaz') {
    await exportDocumentAsPng(context, ref, doc);
    return;
  }
  final choice = await _askPaper(
      context, doc, context.t('Görüntü kâğıt rengi', 'Image paper color'));
  if (choice == null || !context.mounted) return;
  await exportDocumentAsPng(context, ref, doc, paper: choice);
}

/// Notu **PNG görüntü** olarak dışa aktarır; kullanıcı kayıt konumunu seçer
/// (sonra galeriden/dosyalardan paylaşabilir — uygulamada share_plus yok).
/// Çok sayfalı notta tüm sayfalar tek bir uzun görüntüde alt alta birleşir;
/// çok uzun notlarda bellek için genişlik otomatik küçültülür.
Future<void> exportDocumentAsPng(
  BuildContext context,
  WidgetRef ref,
  Document doc, {
  PdfPaper paper = PdfPaper.white,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final okMsg = context.t('Görüntü kaydedildi', 'Image saved');
  final failMsg =
      context.t('Görüntü kaydedilemedi', 'Image could not be saved');
  final saveTitle = context.t('Görüntüyü kaydet', 'Save image');

  final pal = _pdfPalette(doc.pageColor, paper);
  final rows = await ref.read(drawingRepositoryProvider).getStrokes(doc.id);
  final aspect = aspectForPageSize(doc.pageSize);
  var pageCount = doc.pageCount ?? 1;

  // Form notu: ekranla aynı sanal metriklerle sayfalanır (PDF ile birebir).
  FormDoc? form;
  FormLayoutResult? formLayout;
  FormMetrics? metrics;
  if (isFormBody(doc.body)) {
    form = FormDoc.tryParse(doc.body);
    if (form != null) {
      metrics = formMetrics(doc.pageSize);
      formLayout = paginateForm(
          form, metrics.virtualW, metrics.contentH, metrics.pageSkip,
          editable: false);
      if (formLayout.pages > pageCount) pageCount = formLayout.pages;
    }
  }
  if (pageCount < 1) pageCount = 1;

  // Sayfa aralığı (görüntüde ince ayraç) ve bellek bütçesi. Toplam piksel
  // ~20 MP'yi aşarsa genişlik küçültülür (uzun notlarda bellek taşmasın).
  const gapRatio = 0.02;
  const budget = 20000000.0;
  final totalRatio = pageCount * aspect + (pageCount - 1) * gapRatio;
  var w = 1240.0;
  if (w * w * totalRatio > budget) w = math.sqrt(budget / totalRatio);
  final h = w * aspect;
  final gap = w * gapRatio;
  final totalH = pageCount * h + (pageCount - 1) * gap;
  final formScale = metrics == null ? 1.0 : w / metrics.virtualPageW;

  final allStrokes = [for (final s in rows) PenStroke.fromRow(s)];

  // Her sayfayı ayrı çiz, sonra tek uzun görüntüde birleştir.
  final images = <ui.Image>[];
  for (var i = 0; i < pageCount; i++) {
    images.add(await _renderPageUiImage(
      w,
      h,
      allStrokes,
      body: form == null && i == 0 ? doc.body : null,
      background: doc.pageBackground,
      pal: pal,
      form: form,
      formLayout: formLayout,
      formPage: i,
      formScale: formScale,
      // Çizimler editörün sürekli düzleminde durur → editörün kendi sayfa
      // aralığı (kPageGapRatio) ile kaydırılır, görüntünün ayracıyla değil.
      strokeOffsetY: i * (aspect + kPageGapRatio) * w,
    ));
  }

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(Rect.fromLTWH(0, 0, w, totalH), Paint()..color = pal.line);
  for (var i = 0; i < images.length; i++) {
    canvas.drawImage(images[i], Offset(0, i * (h + gap)), Paint());
  }
  final picture = recorder.endRecording();
  final composite = await picture.toImage(w.round(), totalH.round());
  picture.dispose();
  for (final img in images) {
    img.dispose();
  }
  final data = await composite.toByteData(format: ui.ImageByteFormat.png);
  composite.dispose();
  if (data == null) {
    messenger.showSnackBar(SnackBar(content: Text(failMsg)));
    return;
  }

  try {
    final path = await FilePicker.saveFile(
      dialogTitle: saveTitle,
      fileName: '${_safeName(doc.title)}.png',
      bytes: data.buffer.asUint8List(),
    );
    messenger.showSnackBar(
        SnackBar(content: Text(path == null ? failMsg : okMsg)));
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(failMsg)));
  }
}

/// Bir sayfayı PNG baytlarına çizer (PDF export bunu kullanır).
Future<Uint8List> _renderPageImage(
  double w,
  double h,
  List<PenStroke> strokes, {
  String? body,
  String background = 'duz',
  _PdfPalette pal = _whitePalette,
  FormDoc? form,
  FormLayoutResult? formLayout,
  int formPage = 0,
  double formScale = 1,
  double strokeOffsetY = 0,
}) async {
  final image = await _renderPageUiImage(
    w,
    h,
    strokes,
    body: body,
    background: background,
    pal: pal,
    form: form,
    formLayout: formLayout,
    formPage: formPage,
    formScale: formScale,
    strokeOffsetY: strokeOffsetY,
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

/// Bir sayfayı (kâğıt zemini + deseni + varsa biçimli metin / form blokları +
/// çizimler) bir [ui.Image]'a çizer. [strokeOffsetY] o sayfanın sürekli çizim
/// düzlemindeki üst konumu (piksel). PNG export bunları alt alta birleştirir.
Future<ui.Image> _renderPageUiImage(
  double w,
  double h,
  List<PenStroke> strokes, {
  String? body,
  String background = 'duz',
  _PdfPalette pal = _whitePalette,
  FormDoc? form,
  FormLayoutResult? formLayout,
  int formPage = 0,
  double formScale = 1,
  double strokeOffsetY = 0,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // Ekrandaki (telefon ~390px genişlik) oranı yakalamak için ölçek.
  final scale = w / 390.0;

  canvas.drawRect(
    Rect.fromLTWH(0, 0, w, h),
    Paint()..color = pal.background,
  );

  // Kâğıt deseni (çizgili/kareli/noktalı) — editörle aynı yardımcı.
  paintPageBackground(canvas, Size(w, h), background, pal.line);

  if (form != null && formLayout != null) {
    final pad = 22.0 * formScale;
    _paintForm(canvas, form, formLayout, formPage, pad, pad, w - pad * 2,
        formScale, pal);
  } else if (body != null && body.trim().isNotEmpty) {
    final pad = 22.0 * scale;
    _paintRichText(
      canvas,
      _parseDelta(body, scale, pal.ink),
      pad,
      pad,
      w - pad * 2,
      scale,
      pal,
    );
  }

  canvas.save();
  canvas.translate(0, -strokeOffsetY);
  for (final s in strokes) {
    if (s.points.isEmpty) continue;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s.effectiveWidth * scale;
    switch (s.tool) {
      case PenTool.silgi:
        paint.color = pal.background;
      case PenTool.fosfor:
        paint.color = s.color.withValues(alpha: 0.32);
      case PenTool.kalem:
      case PenTool.el:
      case PenTool.yazi:
        paint.color = s.color;
    }
    canvas.drawPath(s.buildScaledPath(Size(w, h)), paint);
  }
  canvas.restore();

  final picture = recorder.endRecording();
  final image = await picture.toImage(w.round(), h.round());
  picture.dispose();
  return image;
}

// ─────────────────────── Quill Delta → biçimli metin ───────────────────────

const _ink = Color(0xFF262626);

class _Seg {
  _Seg(this.text, this.style);
  final String text;
  final TextStyle style;
}

class _Line {
  _Line(this.segs, this.list);
  final List<_Seg> segs;
  final String? list; // 'bullet' | 'checked' | 'unchecked' | null
}

/// Gövdeye gömülü ndtable bloğu (blok listesinde _Line'larla karışık durur).
class _PdfTable {
  _PdfTable(this.table);
  final NdTable table;
}

TextStyle _baseStyle(double scale, Color ink) => TextStyle(
      color: ink,
      fontFamily: 'InstrumentSans',
      fontSize: 16.0 * scale,
      height: 1.4,
    );

TextStyle _styleFrom(Map attrs, double scale, Color ink) {
  var style = _baseStyle(scale, ink);
  if (attrs['bold'] == true) {
    style = style.copyWith(fontWeight: FontWeight.bold);
  }
  if (attrs['italic'] == true) {
    style = style.copyWith(fontStyle: FontStyle.italic);
  }
  final deco = <TextDecoration>[];
  if (attrs['underline'] == true) deco.add(TextDecoration.underline);
  if (attrs['strike'] == true) deco.add(TextDecoration.lineThrough);
  if (deco.isNotEmpty) {
    style = style.copyWith(decoration: TextDecoration.combine(deco));
  }
  final size = attrs['size'];
  if (size != null) {
    final s = double.tryParse(size.toString());
    if (s != null) style = style.copyWith(fontSize: s * scale);
  }
  return style;
}

/// Quill Delta JSON'ı bloklara ayırır: metin satırları (_Line) + tablolar
/// (_PdfTable). Geçersizse düz metin olarak işler.
List<Object> _parseDelta(String body, double scale, Color ink) {
  final blocks = <Object>[];
  var current = <_Seg>[];

  dynamic data;
  try {
    data = jsonDecode(body);
  } catch (_) {
    data = null;
  }

  if (data is! List) {
    for (final ln in body.split('\n')) {
      blocks.add(_Line([_Seg(ln, _baseStyle(scale, ink))], null));
    }
    return blocks;
  }

  for (final op in data) {
    if (op is! Map) continue;
    final insert = op['insert'];
    if (insert is Map) {
      final nd = insert['ndtable'];
      if (nd is String) {
        if (current.isNotEmpty) {
          blocks.add(_Line(current, null));
          current = <_Seg>[];
        }
        try {
          blocks.add(_PdfTable(NdTable.fromJson(nd)));
        } catch (_) {}
      }
      continue; // diğer gömülüler atlanır
    }
    if (insert is! String) continue;
    final attrs = (op['attributes'] as Map?) ?? const {};
    final parts = insert.split('\n');
    for (var i = 0; i < parts.length; i++) {
      final text = parts[i];
      if (text.isNotEmpty) {
        current.add(_Seg(text, _styleFrom(attrs, scale, ink)));
      }
      if (i < parts.length - 1) {
        // Satır sonu: blok biçimi (liste) bu op'un özniteliğindedir.
        blocks.add(_Line(current, attrs['list'] as String?));
        current = <_Seg>[];
      }
    }
  }
  if (current.isNotEmpty) blocks.add(_Line(current, null));
  return blocks;
}

void _paintRichText(
  Canvas canvas,
  List<Object> blocks,
  double x,
  double y,
  double maxWidth,
  double scale,
  _PdfPalette pal,
) {
  final markerW = 24.0 * scale;
  var cy = y;

  for (final block in blocks) {
    if (block is _PdfTable) {
      cy = _paintTable(canvas, block.table, x, cy, maxWidth, scale, pal);
      continue;
    }
    final line = block as _Line;
    final hasMarker = line.list != null;
    final textX = x + (hasMarker ? markerW : 0);
    final textW = maxWidth - (hasMarker ? markerW : 0);

    final spans = line.segs.isEmpty
        ? [TextSpan(text: ' ', style: _baseStyle(scale, pal.ink))]
        : [for (final s in line.segs) TextSpan(text: s.text, style: s.style)];

    final tp = TextPainter(
      text: TextSpan(children: spans),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: textW < 20 ? 20 : textW);

    final firstLineH = tp.preferredLineHeight;

    if (line.list == 'bullet') {
      canvas.drawCircle(
        Offset(x + markerW / 2, cy + firstLineH / 2),
        2.6 * scale,
        Paint()..color = pal.ink,
      );
    } else if (line.list == 'checked' || line.list == 'unchecked') {
      final side = 13.0 * scale;
      final box = Rect.fromLTWH(
        x + 2 * scale,
        cy + (firstLineH - side) / 2,
        side,
        side,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, Radius.circular(3 * scale)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4 * scale
          ..color = pal.ink,
      );
      if (line.list == 'checked') {
        final path = Path()
          ..moveTo(box.left + 3 * scale, box.center.dy)
          ..lineTo(box.center.dx - 1 * scale, box.bottom - 3.5 * scale)
          ..lineTo(box.right - 2.5 * scale, box.top + 3.5 * scale);
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8 * scale
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = pal.ink,
        );
      }
    }

    tp.paint(canvas, Offset(textX, cy));
    cy += tp.height + 2 * scale;
  }
}

/// ndtable bloğunu çizer (ekrandaki tablo görünümünün PDF karşılığı).
/// Yeni dikey konumu (tablonun altı + boşluk) döndürür.
double _paintTable(
  Canvas canvas,
  NdTable t,
  double x,
  double y,
  double maxWidth,
  double scale,
  _PdfPalette pal,
) {
  final line = pal.line;
  final muted = pal.muted;
  final faint = pal.faint;
  final cellPadH = 8.0 * scale;
  final cellPadV = 7.0 * scale;
  final checkSide = 13.0 * scale;
  final radius = 12.0 * scale;

  final totalFlex = t.widths.fold<int>(0, (a, b) => a + b);
  if (totalFlex <= 0 || t.rows.isEmpty) return y;
  final colWs = [for (final w in t.widths) maxWidth * w / totalFlex];

  TextStyle cellStyle(NdCell c, bool header) => TextStyle(
        color: header || c.muted ? muted : pal.ink,
        fontFamily: 'InstrumentSans',
        fontSize: (header || c.muted ? 11.5 : 13.0) * scale,
        fontWeight: header ? FontWeight.w700 : FontWeight.w400,
        letterSpacing: header ? 0.6 * scale : 0,
        height: 1.35,
      );

  // Satır yükseklikleri: hücre metin yüksekliği vs min satır sayısı.
  final rowHs = <double>[];
  final painters = <List<TextPainter>>[];
  for (var r = 0; r < t.rows.length; r++) {
    final header = t.headerRow && r == 0;
    var rowH = 0.0;
    final rowPainters = <TextPainter>[];
    for (var c = 0; c < t.rows[r].length && c < colWs.length; c++) {
      final cell = t.rows[r][c];
      final checkW = cell.check != null ? checkSide + 7 * scale : 0.0;
      final tp = TextPainter(
        text: TextSpan(
            text: cell.text.isEmpty ? ' ' : cell.text,
            style: cellStyle(cell, header)),
        textDirection: TextDirection.ltr,
      )..layout(
          maxWidth:
              (colWs[c] - cellPadH * 2 - checkW).clamp(10.0, double.infinity));
      rowPainters.add(tp);
      final minH = (14.0 + cell.minLines * 19.0) * scale;
      final h = (tp.height + cellPadV * 2)
          .clamp(minH, double.infinity)
          .toDouble();
      if (h > rowH) rowH = h;
    }
    if (rowH <= 0) rowH = (14.0 + 19.0) * scale;
    rowHs.add(rowH);
    painters.add(rowPainters);
  }
  final tableH = rowHs.fold<double>(0, (a, b) => a + b);
  final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, maxWidth, tableH), Radius.circular(radius));

  canvas.save();
  canvas.clipRRect(outer);

  // Zeminler (başlık satırı + faint hücreler).
  var cy = y;
  for (var r = 0; r < t.rows.length; r++) {
    final header = t.headerRow && r == 0;
    var cx = x;
    for (var c = 0; c < t.rows[r].length && c < colWs.length; c++) {
      final cell = t.rows[r][c];
      if (header || cell.faint) {
        canvas.drawRect(Rect.fromLTWH(cx, cy, colWs[c], rowHs[r]),
            Paint()..color = faint);
      }
      cx += colWs[c];
    }
    cy += rowHs[r];
  }

  // Hücre içerikleri (kutucuk + metin).
  cy = y;
  for (var r = 0; r < t.rows.length; r++) {
    var cx = x;
    for (var c = 0; c < t.rows[r].length && c < colWs.length; c++) {
      final cell = t.rows[r][c];
      var textX = cx + cellPadH;
      final tp = painters[r][c];
      final singleLine = cell.minLines <= 1;
      final textY =
          singleLine ? cy + (rowHs[r] - tp.height) / 2 : cy + cellPadV;
      if (cell.check != null) {
        final boxY = singleLine
            ? cy + (rowHs[r] - checkSide) / 2
            : cy + cellPadV + 2 * scale;
        final box = Rect.fromLTWH(textX, boxY, checkSide, checkSide);
        final checked = cell.check == 1;
        canvas.drawRRect(
          RRect.fromRectAndRadius(box, Radius.circular(4 * scale)),
          checked
              ? (Paint()..color = pal.ink)
              : (Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.4 * scale
                ..color = muted),
        );
        if (checked) {
          final path = Path()
            ..moveTo(box.left + 3 * scale, box.center.dy)
            ..lineTo(box.center.dx - 1 * scale, box.bottom - 3.5 * scale)
            ..lineTo(box.right - 2.5 * scale, box.top + 3.5 * scale);
          canvas.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.8 * scale
              ..strokeCap = StrokeCap.round
              ..color = pal.background,
          );
        }
        textX += checkSide + 7 * scale;
      }
      tp.paint(canvas, Offset(textX, textY));
      cx += colWs[c];
    }
    cy += rowHs[r];
  }

  // Izgara çizgileri.
  final gridPaint = Paint()
    ..color = line
    ..strokeWidth = 1.0 * scale;
  cy = y;
  for (var r = 0; r < t.rows.length - 1; r++) {
    cy += rowHs[r];
    canvas.drawLine(Offset(x, cy), Offset(x + maxWidth, cy), gridPaint);
  }
  var cx = x;
  for (var c = 0; c < colWs.length - 1; c++) {
    cx += colWs[c];
    canvas.drawLine(Offset(cx, y), Offset(cx, y + tableH), gridPaint);
  }

  canvas.restore();

  // Dış çerçeve.
  canvas.drawRRect(
    outer,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 * scale
      ..color = line,
  );

  return y + tableH + 8 * scale;
}

// ─────────────────────── Form-not (ndform) çizimi ───────────────────────

TextPainter _formTp(String text, TextStyle style, double maxWidth) {
  return TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: maxWidth < 10 ? 10 : maxWidth);
}

TextStyle _fStyle(double size, double scale,
        {Color color = _ink,
        FontWeight weight = FontWeight.w400,
        double letterSpacing = 0}) =>
    TextStyle(
      color: color,
      fontFamily: 'InstrumentSans',
      fontSize: size * scale,
      fontWeight: weight,
      letterSpacing: letterSpacing * scale,
      height: 1.3,
    );

/// Form-notun [page] sayfasına düşen bloklarını canvas'a çizer — ekrandaki
/// FormPage düzeninin (ve sayfalamasının) PDF karşılığı.
void _paintForm(
  Canvas canvas,
  FormDoc form,
  FormLayoutResult layout,
  int page,
  double x,
  double y,
  double maxWidth,
  double scale,
  _PdfPalette pal,
) {
  var cy = y;

  // Form yazı stili — varsayılan renk paletin mürekkebi (kâğıt rengine uyar).
  TextStyle ts(double size, double s,
          {Color? color,
          FontWeight weight = FontWeight.w400,
          double letterSpacing = 0}) =>
      _fStyle(size, s,
          color: color ?? pal.ink,
          weight: weight,
          letterSpacing: letterSpacing);

  // Alan biçimleri (kalın/italik/altı çizili) — FormPage'in `_fmt`'iyle aynı
  // anahtar şeması, böylece ekranda ne varsa çıktıda da görünür.
  TextStyle fmt(String key, TextStyle base) {
    final flags = form.styles[key];
    if (flags == null || flags.isEmpty) return base;
    return base.copyWith(
      fontWeight: flags.contains(kFmtBold) ? FontWeight.w700 : null,
      fontStyle: flags.contains(kFmtItalic) ? FontStyle.italic : null,
      decoration:
          flags.contains(kFmtUnderline) ? TextDecoration.underline : null,
      decorationColor: base.color,
    );
  }

  void label(String text, {double size = 11}) {
    final tp = _formTp(
        text.toUpperCase(),
        ts(size, scale,
            color: pal.muted, weight: FontWeight.w700, letterSpacing: 1.1),
        maxWidth);
    tp.paint(canvas, Offset(x, cy));
    cy += tp.height + 6 * scale;
  }

  void underline(double lx, double w, double yy) {
    canvas.drawLine(
        Offset(lx, yy),
        Offset(lx + w, yy),
        Paint()
          ..color = pal.line
          ..strokeWidth = 1 * scale);
  }

  void checkbox(double bx, double by, double side, bool done) {
    final box = Rect.fromLTWH(bx, by, side, side);
    if (done) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(box, Radius.circular(side * 0.32)),
          Paint()..color = pal.ink);
      final p = Path()
        ..moveTo(box.left + side * 0.24, box.center.dy)
        ..lineTo(box.center.dx - side * 0.05, box.bottom - side * 0.26)
        ..lineTo(box.right - side * 0.2, box.top + side * 0.28);
      canvas.drawPath(
          p,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8 * scale
            ..strokeCap = StrokeCap.round
            ..color = pal.background);
    } else {
      canvas.drawRRect(
          RRect.fromRectAndRadius(box, Radius.circular(side * 0.32)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8 * scale
            ..color = pal.line);
    }
  }

  void ruled(
      double lx, double w, double top, int lines, double lineH, double bl) {
    for (var k = 0; k < lines; k++) {
      underline(lx, w, top + bl + k * lineH);
    }
  }

  // Satırlı blokların (checklist/numaralı/saat) tek satırını çizen yardımcılar
  // — satır satır sayfalara bölünebildikleri için birim bazlı çizilir.
  void checkRow(int bi, ChecklistBlock b, int r) {
    if (r >= b.items.length) return; // "satır ekle" (PDF'te yok)
    final side = 19.0 * scale;
    final it = b.items[r];
    final rowTop = cy;
    final textX = x + side + 12 * scale;
    final trailW =
        b.trailingHint.isEmpty ? 0.0 : (b.trailingWidth + 6) * scale;
    final tp = _formTp(it.text, fmt('$bi.i$r', ts(14.5, scale)),
        maxWidth - side - 12 * scale - trailW);
    final rowH = kFbCheckRowH * scale;
    checkbox(x, rowTop + (rowH - side) / 2, side, it.done);
    tp.paint(canvas, Offset(textX, rowTop + (rowH - tp.height) / 2));
    if (b.trailingHint.isNotEmpty) {
      final has = it.trailing.isNotEmpty;
      final tt = _formTp(has ? it.trailing : b.trailingHint,
          ts(12.5, scale, color: pal.muted), trailW);
      tt.paint(canvas,
          Offset(x + maxWidth - tt.width, rowTop + (rowH - tt.height) / 2));
    }
    underline(x, maxWidth, rowTop + rowH);
  }

  void numRow(int bi, NumberedBlock b, int r) {
    final chip = 22.0 * scale;
    final rowTop = cy;
    final rowH = kFbNumRowH * scale;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, rowTop + (rowH - chip) / 2, chip, chip),
            Radius.circular(7 * scale)),
        Paint()..color = pal.faint);
    final nt = _formTp(
        '${r + 1}', ts(12, scale, weight: FontWeight.w700), chip);
    nt.paint(canvas,
        Offset(x + (chip - nt.width) / 2, rowTop + (rowH - nt.height) / 2));
    final tp = _formTp(b.items[r], fmt('$bi.n$r', ts(14, scale)),
        maxWidth - chip - 11 * scale);
    tp.paint(canvas,
        Offset(x + chip + 11 * scale, rowTop + (rowH - tp.height) / 2));
    underline(x, maxWidth, rowTop + rowH);
  }

  void hourRow(int bi, HoursBlock b, int r) {
    final rowH = kFbHourRowH * scale;
    final rowTop = cy;
    final row = b.rows[r];
    final lt = _formTp(row.label,
        ts(12, scale, color: pal.muted, weight: FontWeight.w600), 44 * scale);
    lt.paint(canvas, Offset(x, rowTop + (rowH - lt.height) / 2));
    final vt = _formTp(
        row.value, fmt('$bi.h$r', ts(13.5, scale)), maxWidth - 56 * scale);
    vt.paint(canvas, Offset(x + 56 * scale, rowTop + (rowH - vt.height) / 2));
    underline(x, maxWidth, rowTop + rowH);
  }

  for (final u in layout.units) {
    if (u.page != page) continue;
    final b = form.blocks[u.block];
    cy = y + u.top * scale;
    if (u.row >= 0) {
      switch (b) {
        case ChecklistBlock():
          checkRow(u.block, b, u.row);
        case NumberedBlock():
          numRow(u.block, b, u.row);
        case HoursBlock():
          hourRow(u.block, b, u.row);
        default:
          break;
      }
      continue;
    }
    switch (b) {
      case TitleBlock():
        final has = b.text.isNotEmpty;
        final tp = _formTp(
            has ? b.text : b.hint,
            fmt(
                '${u.block}.t',
                ts(22, scale,
                    color: has ? pal.ink : pal.muted,
                    weight: FontWeight.w800)),
            maxWidth - 60 * scale);
        tp.paint(canvas, Offset(x, cy));
        String? counter;
        if (b.counter == 'done') {
          final (d, t) = form.checkCounts();
          counter = '$d / $t';
        } else if (b.counter == 'count') {
          final (_, t) = form.checkCounts();
          counter = '$t ${b.unit}';
        }
        if (counter != null) {
          final ct = _formTp(
              counter,
              ts(13, scale, color: pal.muted, weight: FontWeight.w600),
              60 * scale);
          ct.paint(canvas,
              Offset(x + maxWidth - ct.width, cy + tp.height - ct.height - 2));
        }
        cy += tp.height + 12 * scale;
      case FieldsBlock():
        final gap = 14.0 * scale;
        final totalFlex = b.fields.fold<int>(0, (a, f) => a + f.flex);
        final avail = maxWidth - gap * (b.fields.length - 1);
        var fx = x;
        var rowH = 0.0;
        for (var fi = 0; fi < b.fields.length; fi++) {
          final f = b.fields[fi];
          final w = avail * f.flex / totalFlex;
          var fy = cy;
          if (f.label.isNotEmpty) {
            final lt = _formTp(
                f.label.toUpperCase(),
                ts(10.5, scale,
                    color: pal.muted,
                    weight: FontWeight.w700,
                    letterSpacing: 1.0),
                w);
            lt.paint(canvas, Offset(fx, fy));
            fy += lt.height + 3 * scale;
          }
          final has = f.value.isNotEmpty;
          final vt = _formTp(
              has ? f.value : (f.hint.isEmpty ? '—' : f.hint),
              fmt('${u.block}.f$fi',
                  ts(14, scale, color: has ? pal.ink : pal.muted)),
              w);
          vt.paint(canvas, Offset(fx, fy));
          fy += vt.height + 6 * scale;
          underline(fx, w, fy);
          if (fy - cy > rowH) rowH = fy - cy;
          fx += w + gap;
        }
        cy += rowH + 14 * scale;
      case LabelBlock():
        cy += 4 * scale;
        label(b.text);
        cy += 4 * scale;
      case ChecklistBlock():
        break; // satır bazlı çizilir (checkRow)
      case NumberedBlock():
        break; // satır bazlı çizilir (numRow)
      case AreaBlock():
        final lineH = 30.0 * scale;
        final has = b.value.isNotEmpty;
        final tp = _formTp(
            has ? b.value : b.hint,
            fmt(
                '${u.block}.a',
                TextStyle(
                  color: has ? pal.ink : pal.muted,
                  fontFamily: 'InstrumentSans',
                  fontSize: 14 * scale,
                  height: 30 / 14,
                )),
            maxWidth);
        final lines = ((tp.height / lineH).ceil()).clamp(b.minLines, 200);
        if (b.lined) {
          ruled(x, maxWidth, cy, lines, lineH,
              ruledBaseline(14, kFbAreaLineH) * scale);
        }
        tp.paint(canvas, Offset(x, cy));
        cy += lines * lineH + 14 * scale;
      case MoodBlock():
        final d = 26.0 * scale;
        var mx = x;
        if (b.label.isNotEmpty) {
          final lt = _formTp(
              b.label,
              ts(12, scale, color: pal.muted, weight: FontWeight.w600),
              maxWidth / 2);
          lt.paint(canvas, Offset(x, cy + (d - lt.height) / 2));
          mx += lt.width + 12 * scale;
        }
        for (var k = 0; k < b.count; k++) {
          final c = Offset(mx + d / 2, cy + d / 2);
          if (b.selected == k) {
            canvas.drawCircle(c, d / 2, Paint()..color = pal.ink);
          } else {
            canvas.drawCircle(
                c,
                d / 2 - 0.9 * scale,
                Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 1.8 * scale
                  ..color = pal.line);
          }
          mx += d + 10 * scale;
        }
        cy += d + 14 * scale;
      case HoursBlock():
        break; // satır bazlı çizilir (hourRow)
      case WeekBlock():
        final gap = 6.0 * scale;
        final colW = (maxWidth - gap * (b.days.length - 1)) / b.days.length;
        final side = 15.0 * scale;
        final itemH = side + 6 * scale;
        final headH = 20.0 * scale;
        final pad = 7.0 * scale;
        final maxItems = b.days
            .fold<int>(0, (a, d) => d.items.length > a ? d.items.length : a);
        final colH = pad * 2 + headH + maxItems * itemH;
        var dx = x;
        for (var di = 0; di < b.days.length; di++) {
          final d = b.days[di];
          final rect = Rect.fromLTWH(dx, cy, colW, colH);
          final rr =
              RRect.fromRectAndRadius(rect, Radius.circular(11 * scale));
          if (d.faint) canvas.drawRRect(rr, Paint()..color = pal.faint);
          canvas.drawRRect(
              rr,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1 * scale
                ..color = pal.line);
          final nt = _formTp(d.name, ts(12, scale, weight: FontWeight.w700),
              colW - pad * 2);
          nt.paint(canvas, Offset(dx + pad, cy + pad));
          var iy = cy + pad + headH;
          for (var ri = 0; ri < d.items.length; ri++) {
            final it = d.items[ri];
            checkbox(dx + pad, iy, side, it.done);
            final tt = _formTp(it.text, fmt('${u.block}.d$di.$ri', ts(11, scale)),
                colW - pad * 2 - side - 5 * scale);
            tt.paint(canvas,
                Offset(dx + pad + side + 5 * scale, iy + (side - tt.height) / 2));
            iy += itemH;
          }
          dx += colW + gap;
        }
        cy += colH + 14 * scale;
      case CornellBlock():
        final lineH = 27.0 * scale;
        const cueLines = 12;
        final pad = 12.0 * scale;
        final labelH = 16.0 * scale;
        final boxH = pad * 2 + labelH + cueLines * lineH;
        final rect = Rect.fromLTWH(x, cy, maxWidth, boxH);
        final rr = RRect.fromRectAndRadius(rect, Radius.circular(14 * scale));
        final cueW = maxWidth * 9 / 25;
        canvas.save();
        canvas.clipRRect(rr);
        canvas.drawRect(
            Rect.fromLTWH(x, cy, cueW, boxH), Paint()..color = pal.faint);
        canvas.drawLine(
            Offset(x + cueW, cy),
            Offset(x + cueW, cy + boxH),
            Paint()
              ..color = pal.line
              ..strokeWidth = 1.5 * scale);
        void cornellArea(
            String key, double ax, double aw, String lbl, String val) {
          final lt = _formTp(
              lbl.toUpperCase(),
              ts(10, scale,
                  color: pal.muted, weight: FontWeight.w700, letterSpacing: 0.8),
              aw - pad * 2);
          lt.paint(canvas, Offset(ax + pad, cy + pad));
          ruled(ax + pad, aw - pad * 2, cy + pad + labelH, cueLines, lineH,
              ruledBaseline(13, kFbCornellLineH) * scale);
          if (val.isNotEmpty) {
            final vt = _formTp(
                val,
                fmt(
                    key,
                    TextStyle(
                      color: pal.ink,
                      fontFamily: 'InstrumentSans',
                      fontSize: 13 * scale,
                      height: 27 / 13,
                    )),
                aw - pad * 2);
            vt.paint(canvas, Offset(ax + pad, cy + pad + labelH));
          }
        }

        cornellArea('${u.block}.c', x, cueW, b.cuesLabel, b.cues);
        cornellArea('${u.block}.n', x + cueW, maxWidth - cueW, b.notesLabel,
            b.notes);
        canvas.restore();
        canvas.drawRRect(
            rr,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5 * scale
              ..color = pal.line);
        cy += boxH + 12 * scale;
        // Özet kutusu.
        const sumLines = 3;
        final sumH = pad * 2 + labelH + sumLines * lineH;
        final srr = RRect.fromRectAndRadius(
            Rect.fromLTWH(x, cy, maxWidth, sumH), Radius.circular(14 * scale));
        final st = _formTp(
            b.summaryLabel.toUpperCase(),
            ts(10, scale,
                color: pal.muted, weight: FontWeight.w700, letterSpacing: 0.8),
            maxWidth - pad * 2);
        st.paint(canvas, Offset(x + pad, cy + pad));
        ruled(x + pad, maxWidth - pad * 2, cy + pad + labelH, sumLines, lineH,
            ruledBaseline(13, kFbCornellLineH) * scale);
        if (b.summary.isNotEmpty) {
          final vt = _formTp(
              b.summary,
              fmt(
                  '${u.block}.s',
                  TextStyle(
                    color: pal.ink,
                    fontFamily: 'InstrumentSans',
                    fontSize: 13 * scale,
                    height: 27 / 13,
                  )),
              maxWidth - pad * 2);
          vt.paint(canvas, Offset(x + pad, cy + pad + labelH));
        }
        canvas.drawRRect(
            srr,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5 * scale
              ..color = pal.line);
        cy += sumH + 14 * scale;
      case SketchBlock():
        final h = b.height * scale;
        final rr = RRect.fromRectAndRadius(
            Rect.fromLTWH(x, cy, maxWidth, h), Radius.circular(14 * scale));
        final dot = Paint()..color = pal.line;
        for (var yy = cy + 12 * scale;
            yy < cy + h - 4 * scale;
            yy += 15 * scale) {
          for (var xx = x + 12 * scale;
              xx < x + maxWidth - 4 * scale;
              xx += 15 * scale) {
            canvas.drawCircle(Offset(xx, yy), 1.1 * scale, dot);
          }
        }
        final border = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6 * scale
          ..color = pal.line;
        final path = Path()..addRRect(rr);
        final dash = 7.0 * scale, gapLen = 5.0 * scale;
        for (final metric in path.computeMetrics()) {
          var dist = 0.0;
          while (dist < metric.length) {
            canvas.drawPath(
                metric.extractPath(dist, (dist + dash).clamp(0, metric.length)),
                border);
            dist += dash + gapLen;
          }
        }
        cy += h + 14 * scale;
    }
  }
}
