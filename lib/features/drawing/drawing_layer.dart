import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
import '../../data/database/database.dart';
import 'drawing_state.dart';
import 'stroke_painter.dart';

/// İçeriğin (not / PDF sayfası) üzerine yerleştirilen çizim katmanı.
///
/// - "El" aracı seçiliyken dokunuşu alta geçirir (kaydırma / yazma çalışır).
/// - Kalem/fosforlu/silgi seçiliyken:
///   - **tek parmak** çizer (sayfa kilitlenir),
///   - **iki parmak** kaydırır ([onPanScroll]) ve yakınlaştırır ([onPinch]),
///   - **iki parmakla kısa dokunuş** son çizimi geri alır.
class DrawingLayer extends ConsumerStatefulWidget {
  const DrawingLayer({
    super.key,
    required this.docId,
    this.page = 0,
    this.onPanScroll,
    this.onPinch,
  });

  final int docId;
  final int page;

  /// İki parmakla kaydırırken dikey hareket (orta noktanın dy'si).
  final void Function(double dy)? onPanScroll;

  /// İki parmakla yakınlaştırırken artımlı ölçek çarpanı (yeni/eski mesafe).
  final void Function(double scale)? onPinch;

  @override
  ConsumerState<DrawingLayer> createState() => _DrawingLayerState();
}

class _DrawingLayerState extends ConsumerState<DrawingLayer> {
  final Map<int, Offset> _pos = {}; // aktif işaretçilerin genel konumları

  // Kalıcı çizimleri önbellekle (her setState'te JSON çözmemek için).
  List<Stroke>? _cachedRows;
  List<PenStroke> _cachedPersisted = const [];

  PenStroke? _live;
  int? _drawPointer;
  // Şekil modu çizerken sabit başlangıç noktası (normalize) ve o çizim için
  // dondurulmuş şekil türü.
  Offset? _shapeStart;
  ShapeMode _shapeMode = ShapeMode.serbest;

  bool _twoFinger = false;
  double? _lastDist;
  Offset? _lastMid;
  bool _twoMoved = false;
  DateTime? _twoStart;

  final List<PenStroke> _pending = [];
  int _lastCount = 0;

  void _repaint() {
    if (mounted) setState(() {});
  }

  Offset _norm(Offset local, Size size) {
    if (size.width <= 0) return Offset.zero;
    // Her iki eksen de genişliğe göre normalize edilir (yükseklikten bağımsız).
    return Offset(local.dx / size.width, local.dy / size.width);
  }

  void _onDown(PointerDownEvent e, Size size) {
    _pos[e.pointer] = e.position;

    if (_pos.length == 1) {
      _twoFinger = false;
      _drawPointer = e.pointer;
      final color = inkColorFor(
        ref.read(penPaletteProvider),
        ref.read(inkIndexProvider),
        ref.read(customInkColorProvider),
      );
      final width =
          kStrokeSizes[ref.read(sizeIndexProvider) % kStrokeSizes.length];
      final tool = ref.read(toolProvider);
      // Şekil modu yalnızca kalem/fosfor için; silgi her zaman serbest.
      _shapeMode = tool == PenTool.silgi
          ? ShapeMode.serbest
          : ref.read(shapeModeProvider);
      final start = _norm(e.localPosition, size);
      _shapeStart = _shapeMode == ShapeMode.serbest ? null : start;
      _live = PenStroke(
        tool: tool,
        color: color,
        width: width,
        points: [start],
      );
      _repaint();
    } else if (_pos.length == 2) {
      // İkinci parmak → çizimi iptal edip iki-parmak kipine geç.
      _twoFinger = true;
      _drawPointer = null;
      if (_live != null) {
        _live = null;
        _repaint();
      }
      final pts = _pos.values.toList();
      _lastDist = (pts[0] - pts[1]).distance;
      _lastMid = (pts[0] + pts[1]) / 2;
      _twoMoved = false;
      _twoStart = DateTime.now();
    }
  }

  void _onMove(PointerMoveEvent e, Size size) {
    if (_pos.containsKey(e.pointer)) _pos[e.pointer] = e.position;

    if (_twoFinger) {
      if (_pos.length >= 2) {
        final pts = _pos.values.toList();
        final dist = (pts[0] - pts[1]).distance;
        final mid = (pts[0] + pts[1]) / 2;

        if (_lastDist != null && _lastDist! > 0 && widget.onPinch != null) {
          final scale = dist / _lastDist!;
          if ((scale - 1).abs() > 0.002) widget.onPinch!(scale);
        }
        if (_lastMid != null) {
          final dy = mid.dy - _lastMid!.dy;
          if (dy.abs() > 0.01) widget.onPanScroll?.call(dy);
        }
        if (_lastDist != null && (dist - _lastDist!).abs() > 6) _twoMoved = true;
        if (_lastMid != null && (mid - _lastMid!).distance > 6) _twoMoved = true;

        _lastDist = dist;
        _lastMid = mid;
      }
      return;
    }

    if (_live != null && e.pointer == _drawPointer) {
      final cur = _norm(e.localPosition, size);
      if (_shapeMode != ShapeMode.serbest && _shapeStart != null) {
        // Şekil: her harekette başlangıç→güncel arasını yeniden hesapla.
        _live!.points
          ..clear()
          ..addAll(buildShapePoints(_shapeMode, _shapeStart!, cur));
      } else {
        _live!.points.add(cur);
      }
      _repaint();
    }
  }

  void _onUp(PointerEvent e) {
    if (e.pointer == _drawPointer) {
      final live = _live;
      if (live != null) {
        _live = null;
        _pending.add(live);
        ref.read(drawingRepositoryProvider).addStroke(
              docId: widget.docId,
              page: widget.page,
              tool: live.tool.id,
              color: live.color.toARGB32(),
              width: live.width,
              pointsJson: PenStroke.encodePoints(live.points),
            );
        _repaint();
      }
      _drawPointer = null;
    }

    final wasTwo = _twoFinger;
    _pos.remove(e.pointer);

    if (wasTwo && _pos.length < 2) {
      // İki-parmak jesti bitti: hareketsiz + kısa süre ise "geri al" dokunuşu.
      final quick = _twoStart != null &&
          DateTime.now().difference(_twoStart!).inMilliseconds < 300;
      if (!_twoMoved && quick) {
        ref.read(drawingRepositoryProvider).undoLastForDoc(widget.docId);
      }
      _twoFinger = false;
      _lastDist = null;
      _lastMid = null;
    }
    if (_pos.isEmpty) {
      _twoFinger = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tool = ref.watch(toolProvider);
    final rows = ref.watch(activeStrokesProvider).valueOrNull ?? const [];

    // Kalıcı çizimleri yalnızca akış değiştiğinde yeniden çöz (çizim sırasında
    // her setState'te değil).
    if (!identical(rows, _cachedRows)) {
      _cachedRows = rows;
      _cachedPersisted = <PenStroke>[
        for (final r in rows)
          if (r.page == widget.page) PenStroke.fromRow(r),
      ];
    }
    final persisted = _cachedPersisted;

    if (persisted.length != _lastCount) {
      _pending.clear();
      _lastCount = persisted.length;
    }

    final combined = <PenStroke>[...persisted, ..._pending];
    final enabled = tool.isPen;

    final paint = CustomPaint(
      size: Size.infinite,
      painter: StrokePainter(strokes: combined, live: _live),
    );

    if (!enabled) {
      return IgnorePointer(child: paint);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) => _onDown(e, size),
          onPointerMove: (e) => _onMove(e, size),
          onPointerUp: _onUp,
          onPointerCancel: _onUp,
          child: paint,
        );
      },
    );
  }
}
