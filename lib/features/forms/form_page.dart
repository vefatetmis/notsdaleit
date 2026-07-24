import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/i18n.dart';
import '../editor/editor_state.dart';
import 'form_layout.dart';
import 'form_model.dart';

/// Form-notu sayfada çizen ve düzenleten widget. Tasarımdaki ("Not Şablonları"
/// handoff) düzenlerin birebir Flutter karşılığı: etiketli altı çizili alanlar,
/// işaretlenebilir kutucuklar, 7 kolonlu hafta ızgarası, Cornell kolonları,
/// saat çizelgesi, ruh hâli daireleri, eskiz kutusu. Gerçek TextField'lar
/// kullanılır → klavye/odak sorunsuz (Quill'e gömülmez).
class FormPage extends ConsumerStatefulWidget {
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
  ConsumerState<FormPage> createState() => _FormPageState();
}

class _FormPageState extends ConsumerState<FormPage> {
  final Map<String, TextEditingController> _ctrls = {};
  final Map<String, FocusNode> _focusNodes = {};
  String? _activeKey;

  /// Tablo hücresi anahtarı → o hücrenin satır/sütun menüsünü açan kanca.
  /// Her build'de yeniden kurulur (satır/sütun silinince bayat kalmasın).
  final Map<String, VoidCallback> _tableMenus = {};

  TextEditingController _ctrl(String key, String value) {
    final c = _ctrls.putIfAbsent(key, () => TextEditingController(text: value));
    return c;
  }

  /// Alanın odak düğümü. Odaklanınca araç çubuğuna "bu alanı biçimlendir"
  /// bilgisini yayınlar; odak kaybında temizler.
  FocusNode _focusFor(String key) {
    return _focusNodes.putIfAbsent(key, () {
      final node = FocusNode();
      node.addListener(() {
        if (!mounted) return;
        if (node.hasFocus) {
          _publishActive(key);
        } else if (_activeKey == key) {
          _activeKey = null;
          ref.read(activeFormFieldProvider.notifier).state = null;
        }
      });
      return node;
    });
  }

  void _publishActive(String key) {
    _activeKey = key;
    ref.read(activeFormFieldProvider.notifier).state = ActiveFormField(
      flags: widget.form.styles[key] ?? '',
      toggle: (flag) {
        if (!mounted) return;
        setState(() => widget.form.toggleFmt(key, flag));
        widget.onChanged();
        // Çubuktaki açık/kapalı durumu güncellensin.
        _publishActive(key);
      },
      tableMenu: _tableMenus[key],
    );
  }

  /// Alanın kayıtlı biçimini (kalın/italik/altı çizili) taban stile uygular.
  TextStyle _fmt(String key, TextStyle base) {
    final flags = widget.form.styles[key];
    if (flags == null || flags.isEmpty) return base;
    return base.copyWith(
      fontWeight: flags.contains(kFmtBold) ? FontWeight.w700 : null,
      fontStyle: flags.contains(kFmtItalic) ? FontStyle.italic : null,
      decoration:
          flags.contains(kFmtUnderline) ? TextDecoration.underline : null,
      decorationColor: base.color,
    );
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
        case TableBlock():
          for (var r = 0; r < b.rows.length; r++) {
            for (var c = 0; c < b.rows[r].length; c++) {
              sync('$i.t${r}_$c', b.rows[r][c]);
            }
          }
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
    for (final n in _focusNodes.values) {
      n.dispose();
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
        focusNode: _focusFor(key),
        enabled: widget.editable,
        onChanged: (v) {
          onText?.call(v);
          _changed();
        },
        textCapitalization: TextCapitalization.sentences,
        style: _fmt(
            key, TextStyle(fontSize: fontSize, height: 1.3, color: paper.text)),
        decoration: _bare(hint),
      ),
    );
  }

  Widget _checkbox(bool done, VoidCallback onTap,
      {double side = 19, VoidCallback? onLongPress}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.editable ? onTap : null,
      onLongPress: widget.editable ? onLongPress : null,
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
          focusNode: _focusFor(key),
          enabled: widget.editable,
          onChanged: (v) {
            b.value = v;
            _changed();
          },
          maxLines: null,
          minLines: b.minLines,
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.multiline,
          style: _fmt(key,
              TextStyle(fontSize: 14, height: lineH / 14, color: paper.text)),
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
            focusNode: _focusFor('$i.t'),
            enabled: widget.editable,
            onChanged: (v) {
              b.text = v;
              _changed();
            },
            textCapitalization: TextCapitalization.sentences,
            style: _fmt(
              '$i.t',
              TextStyle(
                fontSize: 22,
                height: 1.3,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: paper.text,
              ),
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

  /// Bir bloğun satır controller'larını temizler (silme/ekleme sonrası index
  /// tabanlı controller'lar kaydığı için yeniden kurulmaları gerekir).
  void _clearBlockCtrls(int block) {
    _ctrls.removeWhere((k, c) {
      if (k.startsWith('$block.i') || k.startsWith('$block.x')) {
        c.dispose();
        return true;
      }
      return false;
    });
  }

  void _deleteChecklistItem(int block, int r, ChecklistBlock b) {
    if (b.items.length <= 1) return;
    final removed = b.items[r];
    setState(() {
      b.items.removeAt(r);
      _clearBlockCtrls(block);
    });
    _changed();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(context.t('Satır silindi', 'Row deleted')),
        action: SnackBarAction(
          label: context.t('Geri al', 'Undo'),
          onPressed: () {
            setState(() {
              b.items.insert(r.clamp(0, b.items.length), removed);
              _clearBlockCtrls(block);
            });
            _changed();
          },
        ),
      ));
  }

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
                _checkbox(
                  b.items[r].done,
                  () {
                    setState(() => b.items[r].done = !b.items[r].done);
                    _changed();
                  },
                  onLongPress: b.items.length > 1
                      ? () => _deleteChecklistItem(i, r, b)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _ctrl('$i.i$r', b.items[r].text),
                    focusNode: _focusFor('$i.i$r'),
                    enabled: widget.editable,
                    onChanged: (v) {
                      b.items[r].text = v;
                      _changed();
                    },
                    textCapitalization: TextCapitalization.sentences,
                    style: _fmt('$i.i$r',
                        TextStyle(fontSize: 14.5, height: 1.3, color: paper.text)),
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
                    focusNode: _focusFor('$i.n$r'),
                    enabled: widget.editable,
                    onChanged: (v) {
                      b.items[r] = v;
                      _changed();
                    },
                    textCapitalization: TextCapitalization.sentences,
                    style: _fmt('$i.n$r',
                        TextStyle(fontSize: 14, height: 1.3, color: paper.text)),
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
                    focusNode: _focusFor('$i.h$r'),
                    enabled: widget.editable,
                    onChanged: (v) {
                      b.rows[r].value = v;
                      _changed();
                    },
                    textCapitalization: TextCapitalization.sentences,
                    style: _fmt('$i.h$r',
                        TextStyle(fontSize: 13.5, height: 1.3, color: paper.text)),
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
                              focusNode: _focusFor('$i.d$d.$r'),
                              enabled: widget.editable,
                              onChanged: (v) {
                                b.days[d].items[r].text = v;
                                _changed();
                              },
                              style: _fmt(
                                  '$i.d$d.$r',
                                  TextStyle(
                                      fontSize: 11,
                                      height: 1.3,
                                      color: paper.text)),
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
                  focusNode: _focusFor(key),
                  enabled: widget.editable,
                  onChanged: (v) {
                    onText(v);
                    _changed();
                  },
                  maxLines: null,
                  minLines: minLines,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  style: _fmt(key,
                      TextStyle(fontSize: 13, height: 27 / 13, color: paper.text)),
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

  // ── Tablo ────────────────────────────────────────────────────────────

  /// Bir tablonun hücre controller'larını atar (satır/sütun eklenip silinince
  /// index tabanlı anahtarlar kaydığı için yeniden kurulmaları gerekir).
  void _clearTableCtrls(int block) {
    _ctrls.removeWhere((k, c) {
      if (k.startsWith('$block.t')) {
        c.dispose();
        return true;
      }
      return false;
    });
  }

  /// Tablonun yapısını değiştiren işlemler ortak yol: biçimler (hücre bazlı)
  /// kayan index'lere yapışmasın diye o bloğun biçimleri temizlenir.
  void _editTable(int block, VoidCallback change) {
    setState(() {
      change();
      widget.form.clearStylesForBlock(block);
      _clearTableCtrls(block);
    });
    if (_activeKey != null && _activeKey!.startsWith('$block.')) {
      _activeKey = null;
      ref.read(activeFormFieldProvider.notifier).state = null;
    }
    _changed();
  }

  /// Bir bloğu tamamen kaldırır. Sonraki blokların index'i kaydığı için biçim
  /// anahtarları yeniden numaralanır ve controller'lar sıfırlanır (metinler
  /// modelden yeniden okunur).
  void _deleteBlock(int block) {
    final removed = widget.form.blocks[block];
    void reindex(int at, {required bool inserting}) {
      final old = Map<String, String>.from(widget.form.styles);
      widget.form.styles.clear();
      for (final e in old.entries) {
        final dot = e.key.indexOf('.');
        final bi = dot < 0 ? -1 : int.tryParse(e.key.substring(0, dot)) ?? -1;
        if (bi < 0) continue;
        if (!inserting && bi == at) continue; // silinen bloğun biçimleri gider
        final next = bi > at ? (inserting ? bi + 1 : bi - 1) : bi;
        widget.form.styles['$next${e.key.substring(dot)}'] = e.value;
      }
    }

    void resetCtrls() {
      for (final c in _ctrls.values) {
        c.dispose();
      }
      _ctrls.clear();
    }

    setState(() {
      widget.form.blocks.removeAt(block);
      reindex(block, inserting: false);
      resetCtrls();
    });
    ref.read(activeFormFieldProvider.notifier).state = null;
    _activeKey = null;
    _changed();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(context.t('Tablo silindi', 'Table deleted')),
        action: SnackBarAction(
          label: context.t('Geri al', 'Undo'),
          onPressed: () {
            setState(() {
              widget.form.blocks
                  .insert(block.clamp(0, widget.form.blocks.length), removed);
              reindex(block, inserting: true);
              resetCtrls();
            });
            _changed();
          },
        ),
      ));
  }

  /// Hücreye uzun basınca açılan satır/sütun düzenleme menüsü.
  void _tableMenu(int i, TableBlock b, int r, int c) {
    final nav = Navigator.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        Widget item(IconData icon, String label, VoidCallback onTap,
            {bool danger = false}) {
          final color = danger ? Theme.of(ctx).colorScheme.error : null;
          return ListTile(
            leading: Icon(icon, size: 20, color: color),
            title: Text(label, style: TextStyle(color: color)),
            onTap: () {
              nav.pop();
              onTap();
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${ctx.t('Tablo', 'Table')} · ${ctx.t('satır', 'row')} ${r + 1}, ${ctx.t('sütun', 'column')} ${c + 1}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              item(Icons.keyboard_arrow_up, ctx.t('Üste satır ekle', 'Add row above'),
                  () => _editTable(i, () => b.addRow(r))),
              item(Icons.keyboard_arrow_down, ctx.t('Alta satır ekle', 'Add row below'),
                  () => _editTable(i, () => b.addRow(r + 1))),
              item(Icons.keyboard_arrow_left, ctx.t('Sola sütun ekle', 'Add column left'),
                  () => _editTable(i, () => b.addColumn(c))),
              item(Icons.keyboard_arrow_right, ctx.t('Sağa sütun ekle', 'Add column right'),
                  () => _editTable(i, () => b.addColumn(c + 1))),
              const Divider(height: 1),
              item(
                b.header ? Icons.check_box : Icons.check_box_outline_blank,
                ctx.t('Başlık satırı', 'Header row'),
                () => _editTable(i, () => b.header = !b.header),
              ),
              const Divider(height: 1),
              if (b.rows.length > 1)
                item(Icons.remove_circle_outline, ctx.t('Satırı sil', 'Delete row'),
                    () => _editTable(i, () => b.removeRow(r)),
                    danger: true),
              if (b.cols > 1)
                item(Icons.remove_circle_outline, ctx.t('Sütunu sil', 'Delete column'),
                    () => _editTable(i, () => b.removeColumn(c)),
                    danger: true),
              item(Icons.delete_outline, ctx.t('Tabloyu sil', 'Delete table'),
                  () => _deleteBlock(i),
                  danger: true),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _table(int i, TableBlock b) {
    final line = BorderSide(color: paper.line, width: kFbTableBorder);
    final lineH = kFbTableLineH;

    Widget cell(int r, int c) {
      final key = '$i.t${r}_$c';
      final isHead = b.header && r == 0;
      // Araç çubuğu bu hücre odaklanınca satır/sütun menüsünü açabilsin.
      if (widget.editable) _tableMenus[key] = () => _tableMenu(i, b, r, c);
      return Container(
        decoration: BoxDecoration(
          border: c < b.cols - 1 ? Border(right: line) : null,
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: kFbTableCellPadH, vertical: kFbTableCellPadV),
        child: TextField(
          controller: _ctrl(key, b.rows[r][c]),
          focusNode: _focusFor(key),
          enabled: widget.editable,
          onChanged: (v) {
            // setState: hücre sarınca satır yüksekliği büyüsün (sayfalama
            // kaydetmeden sonraki karede yakalar).
            setState(() => b.rows[r][c] = v);
            _changed();
          },
          maxLines: null,
          textCapitalization: TextCapitalization.sentences,
          style: _fmt(
            key,
            TextStyle(
              fontSize: kFbTableFont,
              height: lineH / kFbTableFont,
              fontWeight: isHead ? FontWeight.w700 : FontWeight.w400,
              color: paper.text,
            ),
          ),
          decoration: _bare(''),
        ),
      );
    }

    return Column(
      children: [
        for (var r = 0; r < b.rows.length; r++) ...[
          if (_rowSpacer(i, r) > 0) SizedBox(height: _rowSpacer(i, r)),
          Container(
            decoration: BoxDecoration(
              color: b.header && r == 0 ? paper.faint : null,
              border: Border(
                top: line,
                left: line,
                right: line,
                bottom: r == b.rows.length - 1 ? line : BorderSide.none,
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var c = 0; c < b.cols; c++) Expanded(child: cell(r, c)),
                ],
              ),
            ),
          ),
        ],
        if (widget.editable) ...[
          if (_rowSpacer(i, b.rows.length) > 0)
            SizedBox(height: _rowSpacer(i, b.rows.length)),
          InkWell(
            onTap: () => _editTable(i, b.addRow),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.add, size: 16, color: paper.muted),
                  const SizedBox(width: 10),
                  Text(
                    context.t('Satır ekle', 'Add row'),
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: paper.muted),
                  ),
                ],
              ),
            ),
          ),
        ],
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
    // Tablo menü kancaları her karede yeniden kurulur (silinen satır/sütuna
    // ait bayat kanca kalmasın).
    _tableMenus.clear();
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
        TableBlock() => _table(i, b),
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
