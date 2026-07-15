import 'dart:convert';

import 'package:flutter/material.dart';

import '../../data/database/database.dart';
import 'drawing_state.dart';

/// Çizim için hafif model. Noktalar 0..1 aralığında normalize edilmiştir.
class PenStroke {
  PenStroke({
    required this.tool,
    required this.color,
    required this.width,
    required this.points,
  });

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
    super.repaint,
  });

  final List<PenStroke> strokes;
  final PenStroke? live;

  @override
  void paint(Canvas canvas, Size size) {
    if (strokes.isEmpty && live == null) return;
    // saveLayer: silginin (BlendMode.clear) yalnızca bu katmanı etkilemesi için.
    canvas.saveLayer(Offset.zero & size, Paint());
    for (final s in strokes) {
      _draw(canvas, size, s);
    }
    if (live != null) _draw(canvas, size, live!);
    canvas.restore();
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
        paint.color = s.color;
    }

    canvas.drawPath(s.buildScaledPath(size), paint);
  }

  @override
  bool shouldRepaint(StrokePainter old) =>
      old.strokes != strokes || old.live != live;
}
