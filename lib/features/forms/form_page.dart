import 'package:flutter/material.dart';

import '../editor/editor_state.dart';
import 'form_layout.dart';
import 'form_model.dart';

/// Form-notu sayfada çizen ve düzenleten widget. Tasarımdaki ("Not Şablonları"
/// handoff) düzenlerin birebir Flutter karşılığı: etiketli altı çizili alanlar,
/// işaretlenebilir kutucuklar, 7 kolonlu hafta ızgarası, Cornell kolonları,
/// saat çizelgesi, ruh hâli daireleri, eskiz kutusu. Gerçek TextField'lar
/// kullanılır → klavye/odak sorunsuz (Quill'e gömülmez).
class FormPage extends StatefulWidget {
  const FormPage({
    super.key,
    required this.form,
    required this.paper,
    required this.editable,
    required this.onChanged,
    this.layout,
  });

  final FormDoc form;
  final PaperStyle paper;
  final bool editable;
  final VoidCallback onChanged;

  /// Sayfalama (`paginateForm` üretir): bloklar/satırlar sayfa sınırını
  /// ortalamak yerine spacer'la sonraki sayfanın başına düşer.
  final FormLayoutResult? layout;

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final Map<String, TextEditingController> _ctrls = {};

  TextEditingController _ctrl(String key, String value) {
    final c = _ctrls.putIfAbsent(key, () => TextEditingController(text: value));
    return c;
  }

  @override
  void didUpdateWidget(FormPage old) {
    super.didUpdateWidget(old);
    // Uzaktan (canlı paylaşım) yeni form geldiyse controller metinlerini eşitle.
    if (!identical(old.form, widget.form)) {
      _syncControllers();
    }
  }

  void _syncControllers() {
    void sync(String key, String value) {
      final c = _ctrls[key];
      if (c != null && c.text != value) c.text = value;
    }

    final blocks = widget.form.blocks;
    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      switch (b) {
        case TitleBlock():
          sync('$i.t', b.text);
        case FieldsBlock():
          for (var f = 0; f < b.fields.length; f++) {
            sync('$i.f$f', b.fields[f].value);
          }
        case ChecklistBlock():
          for (var r = 0; r < b.items.length; r++) {
            sync('$i.i$r', b.items[r].text);
            sync('$i.x$r', b.items[r].trailing);
          }
        case NumberedBlock():
          for (var r = 0; r < b.items.length; r++) {
            sync('$i.n$r', b.items[r]);
          }
        case AreaBlock():
          sync('$i.a', b.value);
        case HoursBlock():
          for (var r = 0; r < b.rows.length; r++) {
            sync('$i.h$r', b.rows[r].value);
          }
        case WeekBlock():
          for (var d = 0; d < b.days.length; d++) {
            sync('$i.d$d.m', b.days[d].meta);
            for (var r = 0; r < b.days[d].items.length; r++) {
              sync('$i.d$d.$r', b.days[d].items[r].text);
            }
          }
        case CornellBlock():
          sync('$i.c', b.cues);
          sync('$i.n', b.notes);
          sync('$i.s', b.summary);
        default:
          break;
      }
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  PaperStyle get paper => widget.paper;

  void _changed() => widget.onChanged();

  // ── Ortak küçük parçalar ─────────────────────────────────────────────

  InputDecoration _bare(String hint) => InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        hintText: hint.isEmpty ? null : hint,
        hintStyle: TextStyle(color: paper.muted),
      );

  Widget _labelText(String s, {double size = 11}) => Text(
        s.toUpperCase(),
        style: TextStyle(
          fontSize: size,
          height: 1.3,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: paper.muted,
        ),
      );

  Widget _underlineField(String key, String value, String hint,
      {double fontSize = 14, ValueChanged<String>? onText}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: paper.line)),
      ),
      padding: const EdgeInsets.only(top: 6, bottom: 7),
      child: TextField(
        controller: _ctrl(key, value),
        enabled: widget.editable,
        onChanged: (v) {
          onText?.call(v);
          _changed();
        },
        textCapitalization: TextCapitalization.sentences,
        style: TextStyle(fontSize: fontSize, height: 1.3, color: paper.text),
        decoration: _bare(hint),
      ),
    );
  }

  Widget _checkbox(bool done, VoidCallback onTap, {double side = 19}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.editable ? onTap : null,
      child: Container(
        width: side,
        height: side,
        decoration: BoxDecoration(
          color: done ? paper.text : Colors.transparent,
          borderRadius: BorderRadius.circular(side * 0.32),
          border: Border.all(
            color: done ? paper.text : paper.line,
            width: 1.8,
          ),
        ),
        child: done
            ? Icon(Icons.check, size: side * 0.62, color: paper.background)
            : null,
      ),
    );
  }

  /// Çizgili çok satırlı yazı alanı (çizgiler yazının taban çizgisine oturur).
  Widget _linedArea(String key, AreaBlock b) {
    const lineH = kFbAreaLineH;
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: b.lined ? _RuledPainter(paper.line, lineH, 14) : null,
          ),
        ),
        TextField(
          controller: _ctrl(key, b.value),
          enabled: widget.editable,
          onChanged: (v) {
            b.value = v;
            _changed();
          },
          maxLines: null,
          minLines: b.minLines,
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.multiline,
          style: TextStyle(
              fontSize: 14, height: lineH / 14, color: paper.text),
          decoration: _bare(b.hint),
        ),
      ],
    );
  }

  // ── Bloklar ──────────────────────────────────────────────────────────

  Widget _title(int i, TitleBlock b) {
    String? counter;
    if (b.counter == 'done') {
      final (done, total) = widget.form.checkCounts();
      counter = '$done / $total';
    } else if (b.counter == 'count') {
      final (_, total) = widget.form.checkCounts();
      counter = '$total ${b.unit}';
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl('$i.t', b.text),
            enabled: widget.editable,
            onChanged: (v) {
              b.text = v;
              _changed();
            },
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(
              fontSize: 22,
              height: 1.3,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: paper.text,
            ),
            decoration: _bare(b.hint),
          ),
        ),
        if (counter != null)
          Text(counter,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: paper.muted)),
      ],
    );
  }

  Widget _fields(int i, FieldsBlock b) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var f = 0; f < b.fields.length; f++) ...[
          if (f > 0) const SizedBox(width: 14),
          Expanded(
            flex: b.fields[f].flex,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (b.fields[f].label.isNotEmpty) ...[
                  _labelText(b.fields[f].label, size: 10.5),
                  const SizedBox(height: 2),
                ],
                _underlineField('$i.f$f', b.fields[f].value,
                    b.fields[f].hint.isEmpty ? '—' : b.fields[f].hint,
                    onText: (v) => b.fields[f].value = v),
              ],
            ),
          ),
        ],
      ],
    );
  }

  double _rowSpacer(int block, int row) =>
      widget.layout?.spacerFor(block, row) ?? 0;

  Widget _checklist(int i, ChecklistBlock b) {
    final trailingW = b.trailingWidth > 0 ? b.trailingWidth : 34.0;
    return Column(
      children: [
        for (var r = 0; r < b.items.length; r++) ...[
          if (_rowSpacer(i, r) > 0) SizedBox(height: _rowSpacer(i, r)),
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: paper.line)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                _checkbox(b.items[r].done, () {
                  setState(() => b.items[r].done = !b.items[r].done);
                  _changed();
                }),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _ctrl('$i.i$r', b.items[r].text),
                    enabled: widget.editable,
                    onChanged: (v) {
                      b.items[r].text = v;
                      _changed();
                    },
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                        fontSize: 14.5, height: 1.3, color: paper.text),
                    decoration: _bare(''),
                  ),
                ),
                if (b.trailingHint.isNotEmpty)
                  SizedBox(
                    width: trailingW,
                    child: TextField(
                      controller: _ctrl('$i.x$r', b.items[r].trailing),
                      enabled: widget.editable,
                      onChanged: (v) {
                        b.items[r].trailing = v;
                        _changed();
                      },
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 12.5, color: paper.muted),
                      decoration: _bare(b.trailingHint),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (b.addLabel.isNotEmpty && widget.editable) ...[
          if (_rowSpacer(i, b.items.length) > 0)
            SizedBox(height: _rowSpacer(i, b.items.length)),
          InkWell(
            onTap: () {
              setState(() => b.items.add(CheckItem()));
              _changed();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.add, size: 16, color: paper.muted),
                  const SizedBox(width: 10),
                  Text(b.addLabel,
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: paper.muted)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _numbered(int i, NumberedBlock b) {
    return Column(
      children: [
        for (var r = 0; r < b.items.length; r++) ...[
          if (_rowSpacer(i, r) > 0) SizedBox(height: _rowSpacer(i, r)),
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: paper.line)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: paper.faint,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text('${r + 1}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: paper.text)),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: TextField(
                    controller: _ctrl('$i.n$r', b.items[r]),
                    enabled: widget.editable,
                    onChanged: (v) {
                      b.items[r] = v;
                      _changed();
                    },
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                        fontSize: 14, height: 1.3, color: paper.text),
                    decoration: _bare(''),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _mood(int i, MoodBlock b) {
    return Row(
      children: [
        if (b.label.isNotEmpty) ...[
          Text(b.label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: paper.muted)),
          const SizedBox(width: 12),
        ],
        for (var k = 0; k < b.count; k++)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: widget.editable
                  ? () {
                      setState(() => b.selected = b.selected == k ? -1 : k);
                      _changed();
                    }
                  : null,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: b.selected == k ? paper.text : Colors.transparent,
                  border: Border.all(
                    color: b.selected == k ? paper.text : paper.line,
                    width: 1.8,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _hours(int i, HoursBlock b) {
    return Column(
      children: [
        for (var r = 0; r < b.rows.length; r++) ...[
          if (_rowSpacer(i, r) > 0) SizedBox(height: _rowSpacer(i, r)),
          Container(
            height: 35,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: paper.line)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text(b.rows[r].label,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: paper.muted)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _ctrl('$i.h$r', b.rows[r].value),
                    enabled: widget.editable,
                    onChanged: (v) {
                      b.rows[r].value = v;
                      _changed();
                    },
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                        fontSize: 13.5, height: 1.3, color: paper.text),
                    decoration: _bare(''),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _week(int i, WeekBlock b) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var d = 0; d < b.days.length; d++) ...[
          if (d > 0) const SizedBox(width: 6),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(7, 8, 7, 8),
              decoration: BoxDecoration(
                color: b.days[d].faint ? paper.faint : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: paper.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.days[d].name,
                      style: TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                          color: paper.text)),
                  const SizedBox(height: 6),
                  for (var r = 0; r < b.days[d].items.length; r++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          _checkbox(
                            b.days[d].items[r].done,
                            () {
                              setState(() => b.days[d].items[r].done =
                                  !b.days[d].items[r].done);
                              _changed();
                            },
                            side: 15,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: TextField(
                              controller: _ctrl(
                                  '$i.d$d.$r', b.days[d].items[r].text),
                              enabled: widget.editable,
                              onChanged: (v) {
                                b.days[d].items[r].text = v;
                                _changed();
                              },
                              style: TextStyle(
                                  fontSize: 11,
                                  height: 1.3,
                                  color: paper.text),
                              decoration: _bare(''),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _cornell(int i, CornellBlock b) {
    Widget area(String key, String label, String value,
        ValueChanged<String> onText, int minLines, {bool faint = false}) {
      return Container(
        padding: const EdgeInsets.all(12),
        color: faint ? paper.faint : Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _labelText(label, size: 10),
            const SizedBox(height: 8),
            Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                      painter: _RuledPainter(paper.line, kFbCornellLineH, 13)),
                ),
                TextField(
                  controller: _ctrl(key, value),
                  enabled: widget.editable,
                  onChanged: (v) {
                    onText(v);
                    _changed();
                  },
                  maxLines: null,
                  minLines: minLines,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                      fontSize: 13, height: 27 / 13, color: paper.text),
                  decoration: _bare(''),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: paper.line, width: 1.5),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 9,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                          right: BorderSide(color: paper.line, width: 1.5)),
                    ),
                    child: area('$i.c', b.cuesLabel, b.cues,
                        (v) => b.cues = v, 12,
                        faint: true),
                  ),
                ),
                Expanded(
                  flex: 16,
                  child: area(
                      '$i.n', b.notesLabel, b.notes, (v) => b.notes = v, 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: paper.line, width: 1.5),
          ),
          child: area(
              '$i.s', b.summaryLabel, b.summary, (v) => b.summary = v, 2),
        ),
      ],
    );
  }

  Widget _sketch(SketchBlock b) {
    return CustomPaint(
      painter: _SketchBoxPainter(paper.line),
      child: SizedBox(width: double.infinity, height: b.height),
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    final blocks = widget.form.blocks;
    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      final w = switch (b) {
        TitleBlock() => _title(i, b),
        FieldsBlock() => _fields(i, b),
        LabelBlock() => Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Align(
                alignment: Alignment.centerLeft, child: _labelText(b.text)),
          ),
        ChecklistBlock() => _checklist(i, b),
        NumberedBlock() => _numbered(i, b),
        AreaBlock() => _linedArea('$i.a', b),
        MoodBlock() => _mood(i, b),
        HoursBlock() => _hours(i, b),
        WeekBlock() => _week(i, b),
        CornellBlock() => _cornell(i, b),
        SketchBlock() => _sketch(b),
      };
      // Sayfalama: bütün-blok birimleri (row == -1) sığmazsa sonraki sayfaya
      // atlar. Satırlı bloklar (checklist/numaralı/saat) kendi satır
      // spacer'larını içeride ekler.
      final spacer = widget.layout?.spacerFor(i, -1) ?? 0;
      if (spacer > 0) children.add(SizedBox(height: spacer));
      children.add(Padding(
        padding: EdgeInsets.only(
            bottom: b is LabelBlock ? kFbLabelGap : kFbBlockGap),
        child: w,
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

/// Satır aralığına oturan yatay arka plan çizgileri (çizgili alanlar).
/// Çizgiler yazının taban çizgisine (baseline) hizalanır.
class _RuledPainter extends CustomPainter {
  _RuledPainter(this.color, this.lineHeight, this.fontSize)
      : _baseline = ruledBaseline(fontSize, lineHeight);

  final Color color;
  final double lineHeight;
  final double fontSize;
  final double _baseline;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var y = _baseline; y < size.height + 1; y += lineHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_RuledPainter old) =>
      old.color != color ||
      old.lineHeight != lineHeight ||
      old.fontSize != fontSize;
}

/// Kesikli çerçeve + noktalı zemin (eskiz kutusu).
class _SketchBoxPainter extends CustomPainter {
  _SketchBoxPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
        Offset.zero & size, const Radius.circular(14));
    // Noktalı zemin.
    final dot = Paint()..color = color;
    for (var y = 12.0; y < size.height - 4; y += 15) {
      for (var x = 12.0; x < size.width - 4; x += 15) {
        canvas.drawCircle(Offset(x, y), 1.1, dot);
      }
    }
    // Kesikli çerçeve.
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = color;
    final path = Path()..addRRect(rrect);
    const dash = 7.0, gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        canvas.drawPath(
            metric.extractPath(dist, (dist + dash).clamp(0, metric.length)),
            border);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_SketchBoxPainter old) => old.color != color;
}
