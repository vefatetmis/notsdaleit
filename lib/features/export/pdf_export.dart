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
    _paintRichText(
      canvas,
      _parseDelta(body, scale),
      pad,
      pad,
      w - pad * 2,
      scale,
    );
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
