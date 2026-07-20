import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/data_providers.dart';
import '../../data/database/database.dart';
import '../drawing/drawing_state.dart';
import '../drawing/stroke_painter.dart';
import '../editor/editor_state.dart';
import '../editor/table_embed.dart';
import '../forms/form_model.dart';

String _safeName(String title) {
  final t = title.trim().isEmpty ? 'not' : title.trim();
  return t.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
}

/// Bir belgeyi PDF olarak dışa aktarır ve paylaşım sayfasını açar.
/// - PDF belgesi → özgün dosya paylaşılır.
/// - Not → her sayfa beyaz zemin + (sayfa 0'da) **biçimli metin** + çizimler.
Future<void> exportDocumentAsPdf(WidgetRef ref, Document doc) async {
  final filename = '${_safeName(doc.title)}.pdf';

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
  final pageCount = doc.pageCount ?? 1;
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

  final pdf = pw.Document();
  for (var i = 0; i < pageCount; i++) {
    final pageStrokes = <PenStroke>[
      for (final s in rows)
        if (s.page == i) PenStroke.fromRow(s),
    ];
    final imageBytes = await _renderPageImage(
      w,
      h,
      pageStrokes,
      // Metin (biçimli) yalnızca ilk sayfaya çizilir.
      body: i == 0 ? doc.body : null,
      background: doc.pageBackground,
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

/// Bir sayfayı (beyaz zemin + kâğıt deseni + varsa biçimli metin + çizimler)
/// PNG'ye çizer.
Future<Uint8List> _renderPageImage(
  double w,
  double h,
  List<PenStroke> strokes, {
  String? body,
  String background = 'duz',
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // Ekrandaki (telefon ~390px genişlik) oranı yakalamak için ölçek.
  final scale = w / 390.0;

  canvas.drawRect(
    Rect.fromLTWH(0, 0, w, h),
    Paint()..color = const Color(0xFFFFFFFF),
  );

  // Kâğıt deseni (çizgili/kareli/noktalı) — editörle aynı yardımcı.
  paintPageBackground(canvas, Size(w, h), background, const Color(0xFFE7E5DF));

  if (body != null && body.trim().isNotEmpty) {
    final pad = 22.0 * scale;
    if (isFormBody(body)) {
      final form = FormDoc.tryParse(body);
      if (form != null) {
        _paintForm(canvas, form, pad, pad, w - pad * 2, scale);
      }
    } else {
      _paintRichText(
        canvas,
        _parseDelta(body, scale),
        pad,
        pad,
        w - pad * 2,
        scale,
      );
    }
  }

  for (final s in strokes) {
    if (s.points.isEmpty) continue;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s.effectiveWidth * scale;
    switch (s.tool) {
      case PenTool.silgi:
        paint.color = const Color(0xFFFFFFFF);
      case PenTool.fosfor:
        paint.color = s.color.withValues(alpha: 0.32);
      case PenTool.kalem:
      case PenTool.el:
      case PenTool.yazi:
        paint.color = s.color;
    }
    canvas.drawPath(s.buildScaledPath(Size(w, h)), paint);
  }

  final picture = recorder.endRecording();
  final image = await picture.toImage(w.round(), h.round());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
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

TextStyle _baseStyle(double scale) => TextStyle(
      color: _ink,
      fontFamily: 'InstrumentSans',
      fontSize: 16.0 * scale,
      height: 1.4,
    );

TextStyle _styleFrom(Map attrs, double scale) {
  var style = _baseStyle(scale);
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
List<Object> _parseDelta(String body, double scale) {
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
      blocks.add(_Line([_Seg(ln, _baseStyle(scale))], null));
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
      if (text.isNotEmpty) current.add(_Seg(text, _styleFrom(attrs, scale)));
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
) {
  final markerW = 24.0 * scale;
  var cy = y;

  for (final block in blocks) {
    if (block is _PdfTable) {
      cy = _paintTable(canvas, block.table, x, cy, maxWidth, scale);
      continue;
    }
    final line = block as _Line;
    final hasMarker = line.list != null;
    final textX = x + (hasMarker ? markerW : 0);
    final textW = maxWidth - (hasMarker ? markerW : 0);

    final spans = line.segs.isEmpty
        ? [TextSpan(text: ' ', style: _baseStyle(scale))]
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
        Paint()..color = _ink,
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
          ..color = _ink,
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
            ..color = _ink,
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
) {
  const line = Color(0xFFE7E5DF);
  const muted = Color(0xFFA6A49D);
  const faint = Color(0xFFF5F3EE);
  final cellPadH = 8.0 * scale;
  final cellPadV = 7.0 * scale;
  final checkSide = 13.0 * scale;
  final radius = 12.0 * scale;

  final totalFlex = t.widths.fold<int>(0, (a, b) => a + b);
  if (totalFlex <= 0 || t.rows.isEmpty) return y;
  final colWs = [for (final w in t.widths) maxWidth * w / totalFlex];

  TextStyle cellStyle(NdCell c, bool header) => TextStyle(
        color: header || c.muted ? muted : _ink,
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
              ? (Paint()..color = _ink)
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
              ..color = const Color(0xFFFFFFFF),
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

const _fLine = Color(0xFFE7E5DF);
const _fMuted = Color(0xFFA6A49D);
const _fFaint = Color(0xFFF5F3EE);

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

/// Form-notu (şablon sayfası) canvas'a çizer — ekrandaki FormPage düzeninin
/// PDF karşılığı.
void _paintForm(
  Canvas canvas,
  FormDoc form,
  double x,
  double y,
  double maxWidth,
  double scale,
) {
  var cy = y;

  void label(String text, {double size = 11}) {
    final tp = _formTp(
        text.toUpperCase(),
        _fStyle(size, scale,
            color: _fMuted, weight: FontWeight.w700, letterSpacing: 1.1),
        maxWidth);
    tp.paint(canvas, Offset(x, cy));
    cy += tp.height + 6 * scale;
  }

  void underline(double lx, double w, double yy) {
    canvas.drawLine(
        Offset(lx, yy),
        Offset(lx + w, yy),
        Paint()
          ..color = _fLine
          ..strokeWidth = 1 * scale);
  }

  void checkbox(double bx, double by, double side, bool done) {
    final box = Rect.fromLTWH(bx, by, side, side);
    if (done) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(box, Radius.circular(side * 0.32)),
          Paint()..color = _ink);
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
            ..color = const Color(0xFFFFFFFF));
    } else {
      canvas.drawRRect(
          RRect.fromRectAndRadius(box, Radius.circular(side * 0.32)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8 * scale
            ..color = _fLine);
    }
  }

  void ruled(double lx, double w, double top, int lines, double lineH) {
    for (var k = 1; k <= lines; k++) {
      underline(lx, w, top + k * lineH - 1 * scale);
    }
  }

  for (final b in form.blocks) {
    switch (b) {
      case TitleBlock():
        final has = b.text.isNotEmpty;
        final tp = _formTp(
            has ? b.text : b.hint,
            _fStyle(22, scale,
                color: has ? _ink : _fMuted, weight: FontWeight.w800),
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
              _fStyle(13, scale, color: _fMuted, weight: FontWeight.w600),
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
        for (final f in b.fields) {
          final w = avail * f.flex / totalFlex;
          var fy = cy;
          if (f.label.isNotEmpty) {
            final lt = _formTp(
                f.label.toUpperCase(),
                _fStyle(10.5, scale,
                    color: _fMuted,
                    weight: FontWeight.w700,
                    letterSpacing: 1.0),
                w);
            lt.paint(canvas, Offset(fx, fy));
            fy += lt.height + 3 * scale;
          }
          final has = f.value.isNotEmpty;
          final vt = _formTp(has ? f.value : (f.hint.isEmpty ? '—' : f.hint),
              _fStyle(14, scale, color: has ? _ink : _fMuted), w);
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
        final side = 19.0 * scale;
        for (final it in b.items) {
          final rowTop = cy;
          final textX = x + side + 12 * scale;
          final trailW =
              b.trailingHint.isEmpty ? 0.0 : (b.trailingWidth + 6) * scale;
          final tp = _formTp(it.text, _fStyle(14.5, scale),
              maxWidth - side - 12 * scale - trailW);
          final rowH = (tp.height + 12 * scale)
              .clamp(side + 12 * scale, 999.0 * scale);
          checkbox(x, rowTop + (rowH - side) / 2, side, it.done);
          tp.paint(canvas, Offset(textX, rowTop + (rowH - tp.height) / 2));
          if (b.trailingHint.isNotEmpty) {
            final has = it.trailing.isNotEmpty;
            final tt = _formTp(has ? it.trailing : b.trailingHint,
                _fStyle(12.5, scale, color: _fMuted), trailW);
            tt.paint(
                canvas,
                Offset(
                    x + maxWidth - tt.width, rowTop + (rowH - tt.height) / 2));
          }
          cy += rowH;
          underline(x, maxWidth, cy);
        }
        cy += 14 * scale;
      case NumberedBlock():
        final chip = 22.0 * scale;
        for (var r = 0; r < b.items.length; r++) {
          final rowTop = cy;
          final rowH = chip + 10 * scale;
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromLTWH(x, rowTop + (rowH - chip) / 2, chip, chip),
                  Radius.circular(7 * scale)),
              Paint()..color = _fFaint);
          final nt = _formTp(
              '${r + 1}', _fStyle(12, scale, weight: FontWeight.w700), chip);
          nt.paint(
              canvas,
              Offset(
                  x + (chip - nt.width) / 2, rowTop + (rowH - nt.height) / 2));
          final tp = _formTp(
              b.items[r], _fStyle(14, scale), maxWidth - chip - 11 * scale);
          tp.paint(canvas,
              Offset(x + chip + 11 * scale, rowTop + (rowH - tp.height) / 2));
          cy += rowH;
          underline(x, maxWidth, cy);
        }
        cy += 14 * scale;
      case AreaBlock():
        final lineH = 30.0 * scale;
        final has = b.value.isNotEmpty;
        final tp = _formTp(
            has ? b.value : b.hint,
            TextStyle(
              color: has ? _ink : _fMuted,
              fontFamily: 'InstrumentSans',
              fontSize: 14 * scale,
              height: 30 / 14,
            ),
            maxWidth);
        final lines = ((tp.height / lineH).ceil()).clamp(b.minLines, 200);
        if (b.lined) ruled(x, maxWidth, cy, lines, lineH);
        tp.paint(canvas, Offset(x, cy));
        cy += lines * lineH + 14 * scale;
      case MoodBlock():
        final d = 26.0 * scale;
        var mx = x;
        if (b.label.isNotEmpty) {
          final lt = _formTp(
              b.label,
              _fStyle(12, scale, color: _fMuted, weight: FontWeight.w600),
              maxWidth / 2);
          lt.paint(canvas, Offset(x, cy + (d - lt.height) / 2));
          mx += lt.width + 12 * scale;
        }
        for (var k = 0; k < b.count; k++) {
          final c = Offset(mx + d / 2, cy + d / 2);
          if (b.selected == k) {
            canvas.drawCircle(c, d / 2, Paint()..color = _ink);
          } else {
            canvas.drawCircle(
                c,
                d / 2 - 0.9 * scale,
                Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 1.8 * scale
                  ..color = _fLine);
          }
          mx += d + 10 * scale;
        }
        cy += d + 14 * scale;
      case HoursBlock():
        final rowH = 35.0 * scale;
        for (final r in b.rows) {
          final lt = _formTp(
              r.label,
              _fStyle(12, scale, color: _fMuted, weight: FontWeight.w600),
              44 * scale);
          lt.paint(canvas, Offset(x, cy + (rowH - lt.height) / 2));
          final vt =
              _formTp(r.value, _fStyle(13.5, scale), maxWidth - 56 * scale);
          vt.paint(canvas, Offset(x + 56 * scale, cy + (rowH - vt.height) / 2));
          cy += rowH;
          underline(x, maxWidth, cy);
        }
        cy += 14 * scale;
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
        for (final d in b.days) {
          final rect = Rect.fromLTWH(dx, cy, colW, colH);
          final rr =
              RRect.fromRectAndRadius(rect, Radius.circular(11 * scale));
          if (d.faint) canvas.drawRRect(rr, Paint()..color = _fFaint);
          canvas.drawRRect(
              rr,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1 * scale
                ..color = _fLine);
          final nt = _formTp(d.name, _fStyle(12, scale, weight: FontWeight.w700),
              colW - pad * 2);
          nt.paint(canvas, Offset(dx + pad, cy + pad));
          var iy = cy + pad + headH;
          for (final it in d.items) {
            checkbox(dx + pad, iy, side, it.done);
            final tt = _formTp(
                it.text, _fStyle(11, scale), colW - pad * 2 - side - 5 * scale);
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
            Rect.fromLTWH(x, cy, cueW, boxH), Paint()..color = _fFaint);
        canvas.drawLine(
            Offset(x + cueW, cy),
            Offset(x + cueW, cy + boxH),
            Paint()
              ..color = _fLine
              ..strokeWidth = 1.5 * scale);
        void cornellArea(double ax, double aw, String lbl, String val) {
          final lt = _formTp(
              lbl.toUpperCase(),
              _fStyle(10, scale,
                  color: _fMuted, weight: FontWeight.w700, letterSpacing: 0.8),
              aw - pad * 2);
          lt.paint(canvas, Offset(ax + pad, cy + pad));
          ruled(ax + pad, aw - pad * 2, cy + pad + labelH, cueLines, lineH);
          if (val.isNotEmpty) {
            final vt = _formTp(
                val,
                TextStyle(
                  color: _ink,
                  fontFamily: 'InstrumentSans',
                  fontSize: 13 * scale,
                  height: 27 / 13,
                ),
                aw - pad * 2);
            vt.paint(canvas, Offset(ax + pad, cy + pad + labelH));
          }
        }

        cornellArea(x, cueW, b.cuesLabel, b.cues);
        cornellArea(x + cueW, maxWidth - cueW, b.notesLabel, b.notes);
        canvas.restore();
        canvas.drawRRect(
            rr,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5 * scale
              ..color = _fLine);
        cy += boxH + 12 * scale;
        // Özet kutusu.
        const sumLines = 3;
        final sumH = pad * 2 + labelH + sumLines * lineH;
        final srr = RRect.fromRectAndRadius(
            Rect.fromLTWH(x, cy, maxWidth, sumH), Radius.circular(14 * scale));
        final st = _formTp(
            b.summaryLabel.toUpperCase(),
            _fStyle(10, scale,
                color: _fMuted, weight: FontWeight.w700, letterSpacing: 0.8),
            maxWidth - pad * 2);
        st.paint(canvas, Offset(x + pad, cy + pad));
        ruled(x + pad, maxWidth - pad * 2, cy + pad + labelH, sumLines, lineH);
        if (b.summary.isNotEmpty) {
          final vt = _formTp(
              b.summary,
              TextStyle(
                color: _ink,
                fontFamily: 'InstrumentSans',
                fontSize: 13 * scale,
                height: 27 / 13,
              ),
              maxWidth - pad * 2);
          vt.paint(canvas, Offset(x + pad, cy + pad + labelH));
        }
        canvas.drawRRect(
            srr,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5 * scale
              ..color = _fLine);
        cy += sumH + 14 * scale;
      case SketchBlock():
        final h = b.height * scale;
        final rr = RRect.fromRectAndRadius(
            Rect.fromLTWH(x, cy, maxWidth, h), Radius.circular(14 * scale));
        final dot = Paint()..color = _fLine;
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
          ..color = _fLine;
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
