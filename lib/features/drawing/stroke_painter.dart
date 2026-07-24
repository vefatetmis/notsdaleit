import 'dart:convert';

import 'package:flutter/material.dart';

import '../../data/database/database.dart';
import 'drawing_state.dart';

/// Çizim için hafif model. Noktalar 0..1 aralığında normalize edilmiştir.
class PenStroke {
  PenStroke({
    this.id,
    required this.tool,
    required this.color,
    required this.width,
    required this.points,
  });

  /// Veritabanı satır id'si (yalnızca kaydedilmiş çizimlerde dolu). Lasso
  /// seçimi çizimleri bu id ile işaretler.
  final int? id;
  final PenTool tool;
  final Color color;
  final double width; // taban kalınlık (px)
  final List<Offset> points;

  /// Veritabanı satırından modele.
  static PenStroke fromRow(Stroke s) {
    final raw = jsonDecode(s.points) as List<dynamic>;
    final pts = <Offset>[];
    for (final p in raw) {
      final l = p as List<dynamic>;
      pts.add(Offset((l[0] as num).toDouble(), (l[1] as num).toDouble()));
    }
    final tool = switch (s.tool) {
      'kalem' => PenTool.kalem,
      'fosfor' => PenTool.fosfor,
      'silgi' => PenTool.silgi,
      _ => PenTool.kalem,
    };
    return PenStroke(
      id: s.id,
      tool: tool,
      color: Color(s.color),
      width: s.width,
      points: pts,
    );
  }

  /// Noktaları JSON'a (kaydetmek için).
  static String encodePoints(List<Offset> pts) {
    return jsonEncode([
      for (final p in pts)
        [double.parse(p.dx.toStringAsFixed(4)), double.parse(p.dy.toStringAsFixed(4))]
    ]);
  }

  /// Araca göre efektif çizgi kalınlığı.
  double get effectiveWidth => switch (tool) {
        PenTool.silgi => width * 8,
        PenTool.fosfor => width * 4.5,
        _ => width,
      };

  /// Normalize noktalardan, [size] boyutuna ölçeklenmiş pürüzsüz (bézier) yol.
  /// Koordinatlar **genişliğe göre** normalize edilir (her iki eksen de
  /// size.width ile ölçeklenir); böylece sayfa yüksekliği büyüse bile çizimler
  /// kaymaz.
  Path buildScaledPath(Size size) {
    final path = Path();
    if (points.isEmpty) return path;
    final pts = [
      for (final p in points) Offset(p.dx * size.width, p.dy * size.width),
    ];
    path.moveTo(pts.first.dx, pts.first.dy);
    if (pts.length == 1) {
      path.lineTo(pts.first.dx + 0.1, pts.first.dy);
    } else if (pts.length == 2) {
      path.lineTo(pts[1].dx, pts[1].dy);
    } else {
      for (var i = 1; i < pts.length - 1; i++) {
        final mid = Offset(
          (pts[i].dx + pts[i + 1].dx) / 2,
          (pts[i].dy + pts[i + 1].dy) / 2,
        );
        path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
      }
      path.lineTo(pts.last.dx, pts.last.dy);
    }
    return path;
  }
}

/// Bir katmandaki (not editörü ya da tek PDF sayfası) çizimleri boyar.
class StrokePainter extends CustomPainter {
  StrokePainter({
    required this.strokes,
    this.live,
    this.lasso,
    this.selectedIds = const <int>{},
    this.moveDelta = Offset.zero,
    this.accent = const Color(0xFF4A6CF7),
    super.repaint,
  });

  final List<PenStroke> strokes;
  final PenStroke? live;

  /// Çizilmekte olan kement yolu (normalize). Kaydedilmez, sadece gösterilir.
  final List<Offset>? lasso;

  /// Lasso ile seçili çizim id'leri (çerçeve + taşıma önizlemesi için).
  final Set<int> selectedIds;

  /// Seçimi taşırken canlı kaydırma farkı (normalize).
  final Offset moveDelta;

  /// Seçim çerçevesi / kement rengi (temanın vurgu rengi).
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (strokes.isEmpty && live == null && lasso == null) return;
    // saveLayer: silginin (BlendMode.clear) yalnızca bu katmanı etkilemesi için.
    canvas.saveLayer(Offset.zero & size, Paint());
    for (final s in strokes) {
      final moving = moveDelta != Offset.zero &&
          s.id != null &&
          selectedIds.contains(s.id);
      if (moving) {
        canvas.save();
        canvas.translate(moveDelta.dx * size.width, moveDelta.dy * size.width);
        _draw(canvas, size, s);
        canvas.restore();
      } else {
        _draw(canvas, size, s);
      }
    }
    if (live != null) _draw(canvas, size, live!);
    canvas.restore();

    // Seçim çerçevesi ve kement yolu çizimin ÜSTÜNE (silgi katmanı dışında).
    if (selectedIds.isNotEmpty) _drawSelection(canvas, size);
    final l = lasso;
    if (l != null && l.length > 1) _drawLasso(canvas, size, l);
  }

  /// Seçili çizimleri saran çerçeve (taşımak için buraya basılır).
  void _drawSelection(Canvas canvas, Size size) {
    double? minX, minY, maxX, maxY;
    for (final s in strokes) {
      if (s.id == null || !selectedIds.contains(s.id)) continue;
      for (final p in s.points) {
        if (minX == null || p.dx < minX) minX = p.dx;
        if (minY == null || p.dy < minY) minY = p.dy;
        if (maxX == null || p.dx > maxX) maxX = p.dx;
        if (maxY == null || p.dy > maxY) maxY = p.dy;
      }
    }
    if (minX == null) return;
    final pad = 8.0;
    final rect = Rect.fromLTRB(
          minX * size.width,
          minY! * size.width,
          maxX! * size.width,
          maxY! * size.width,
        )
            .translate(moveDelta.dx * size.width, moveDelta.dy * size.width)
            .inflate(pad);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(rr, Paint()..color = accent.withValues(alpha: 0.07));
    canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = accent.withValues(alpha: 0.9));
  }

  void _drawLasso(Canvas canvas, Size size, List<Offset> pts) {
    final path = Path()
      ..moveTo(pts.first.dx * size.width, pts.first.dy * size.width);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx * size.width, pts[i].dy * size.width);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = accent.withValues(alpha: 0.08));
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = accent.withValues(alpha: 0.85));
  }

  void _draw(Canvas canvas, Size size, PenStroke s) {
    if (s.points.isEmpty) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s.effectiveWidth;

    switch (s.tool) {
      case PenTool.silgi:
        paint.blendMode = BlendMode.clear;
        paint.color = const Color(0xFF000000);
      case PenTool.fosfor:
        paint.color = s.color.withValues(alpha: 0.32);
      case PenTool.kalem:
      case PenTool.el:
      case PenTool.yazi:
      case PenTool.lasso:
        paint.color = s.color;
    }

    canvas.drawPath(s.buildScaledPath(size), paint);
  }

  @override
  bool shouldRepaint(StrokePainter old) =>
      old.strokes != strokes ||
      old.live != live ||
      old.lasso != lasso ||
      old.selectedIds != selectedIds ||
      old.moveDelta != moveDelta;
}
