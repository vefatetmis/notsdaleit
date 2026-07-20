import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/i18n.dart';
import '../../data/data_providers.dart';
import 'editor_state.dart';

/// notdaleit tablo/ızgara bloğu ("ndtable"): Quill Delta'ya gömülü JSON tablo.
/// Delta'da durduğu için kaydetme, canlı paylaşım (gövde LWW) ve .ntdl
/// otomatik taşır. Şablonlardaki form düzenlerinin (haftalık ızgara, Cornell
/// kolonları, saat çizelgesi, aksiyon listesi) temelidir.
///
/// JSON modeli (anahtarlar kısa — gövdede saklanır):
/// {"w":[1,4],          sütun ağırlıkları (flex)
///  "h":1,              1 → ilk satır başlık (kalın + hafif zemin)
///  "r":[[hücre,...],...]}
/// hücre: {"t":"metin", "k":0|1 (kutucuk; yoksa kutucuk yok),
///         "m":1 (soluk etiket stili), "f":1 (hafif zemin), "n":4 (min satır)}
const String kTableEmbedType = 'ndtable';

class NdCell {
  NdCell({this.text = '', this.check, this.muted = false, this.faint = false, this.minLines = 1});

  String text;
  int? check; // null = kutucuk yok, 0/1 = boş/işaretli
  bool muted;
  bool faint;
  int minLines;

  factory NdCell.fromJson(Map<String, dynamic> j) => NdCell(
        text: (j['t'] as String?) ?? '',
        check: j['k'] is int ? j['k'] as int : null,
        muted: j['m'] == 1,
        faint: j['f'] == 1,
        minLines: (j['n'] as int?) ?? 1,
      );

  Map<String, dynamic> toJson() => {
        if (text.isNotEmpty) 't': text,
        if (check != null) 'k': check,
        if (muted) 'm': 1,
        if (faint) 'f': 1,
        if (minLines != 1) 'n': minLines,
      };
}

class NdTable {
  NdTable({required this.widths, required this.headerRow, required this.rows});

  List<int> widths;
  bool headerRow;
  List<List<NdCell>> rows;

  factory NdTable.fromJson(String data) {
    final j = jsonDecode(data) as Map<String, dynamic>;
    final widths = ((j['w'] as List?) ?? const [1])
        .map((e) => (e as num).toInt())
        .toList();
    final rows = <List<NdCell>>[
      for (final r in (j['r'] as List? ?? const []))
        [
          for (final c in (r as List))
            NdCell.fromJson((c as Map).cast<String, dynamic>()),
        ],
    ];
    return NdTable(widths: widths, headerRow: j['h'] == 1, rows: rows);
  }

  String encode() => jsonEncode({
        'w': widths,
        if (headerRow) 'h': 1,
        'r': [
          for (final r in rows) [for (final c in r) c.toJson()],
        ],
      });

  /// Yeni boş satır (son gövde satırının yapısını kopyalar: kutucuklu hücre
  /// kutucuklu kalır, metinler boşalır).
  List<NdCell> emptyRowLike() {
    final template = rows.isNotEmpty ? rows.last : <NdCell>[];
    return [
      for (var i = 0; i < widths.length; i++)
        NdCell(
          check: i < template.length && template[i].check != null ? 0 : null,
          muted: i < template.length && template[i].muted,
          minLines: i < template.length ? template[i].minLines : 1,
        ),
    ];
  }
}

/// Editörde ndtable embed'ini çizen builder.
class TableEmbedBuilder extends EmbedBuilder {
  const TableEmbedBuilder();

  @override
  String get key => kTableEmbedType;

  @override
  String toPlainText(Embed node) => '\n';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    return _NdTableView(embedContext: embedContext);
  }
}

class _NdTableView extends ConsumerWidget {
  const _NdTableView({required this.embedContext});

  final EmbedContext embedContext;

  NdTable _parse() {
    try {
      return NdTable.fromJson(embedContext.node.value.data as String);
    } catch (_) {
      return NdTable(widths: [1], headerRow: false, rows: [
        [NdCell()],
      ]);
    }
  }

  void _commit(NdTable t) {
    final offset = embedContext.node.documentOffset;
    embedContext.controller.replaceText(
      offset,
      1,
      BlockEmbed(kTableEmbedType, t.encode()),
      null,
    );
  }

  Future<void> _editCell(
      BuildContext context, NdTable t, int row, int col) async {
    final cell = t.rows[row][col];
    final controller = TextEditingController(text: cell.text);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t('Hücreyi düzenle', 'Edit cell')),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: cell.minLines > 2 ? 6 : 3,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.t('Vazgeç', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(context.t('Tamam', 'OK')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;
    cell.text = result.trim();
    _commit(t);
  }

  Future<void> _tableMenu(BuildContext context, NdTable t) async {
    final bodyStart = t.headerRow ? 1 : 0;
    final canDelete = t.rows.length > bodyStart + 1;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_rounded),
              title: Text(context.t('Satır ekle', 'Add row')),
              onTap: () => Navigator.of(context).pop('add'),
            ),
            if (canDelete)
              ListTile(
                leading: const Icon(Icons.remove_rounded),
                title: Text(context.t('Son satırı sil', 'Delete last row')),
                onTap: () => Navigator.of(context).pop('del'),
              ),
          ],
        ),
      ),
    );
    if (action == 'add') {
      t.rows.add(t.emptyRowLike());
      _commit(t);
    } else if (action == 'del' && canDelete) {
      t.rows.removeLast();
      _commit(t);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doc = ref.watch(activeDocumentProvider);
    final paper = paperStyleFor(doc?.pageColor);
    final t = _parse();
    final editable = !embedContext.readOnly;

    Widget cellWidget(int rowIx, int colIx) {
      final cell = t.rows[rowIx][colIx];
      final isHeader = t.headerRow && rowIx == 0;
      final textColor = cell.muted || isHeader ? paper.muted : paper.text;
      final minH = 14.0 + cell.minLines * 19.0;

      final content = Row(
        crossAxisAlignment: cell.minLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          if (cell.check != null) ...[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: editable
                  ? () {
                      cell.check = cell.check == 1 ? 0 : 1;
                      _commit(t);
                    }
                  : null,
              child: Container(
                width: 17,
                height: 17,
                margin: const EdgeInsets.only(right: 7),
                decoration: BoxDecoration(
                  color: cell.check == 1 ? paper.text : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: cell.check == 1 ? paper.text : paper.line,
                    width: 1.6,
                  ),
                ),
                child: cell.check == 1
                    ? Icon(Icons.check,
                        size: 12, color: paper.background)
                    : null,
              ),
            ),
          ],
          Expanded(
            child: Text(
              cell.text,
              style: TextStyle(
                fontSize: isHeader || cell.muted ? 11.5 : 13,
                height: 1.35,
                fontWeight:
                    isHeader ? FontWeight.w700 : FontWeight.w400,
                letterSpacing: isHeader ? 0.6 : 0,
                color: textColor,
              ),
            ),
          ),
        ],
      );

      return Expanded(
        flex: colIx < t.widths.length ? t.widths[colIx] : 1,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: editable ? () => _editCell(context, t, rowIx, colIx) : null,
          child: Container(
            constraints: BoxConstraints(minHeight: minH),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: cell.faint || isHeader
                  ? paper.faint
                  : Colors.transparent,
              border: Border(
                right: colIx < t.widths.length - 1
                    ? BorderSide(color: paper.line)
                    : BorderSide.none,
              ),
            ),
            child: content,
          ),
        ),
      );
    }

    return GestureDetector(
      onLongPress: editable ? () => _tableMenu(context, t) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: paper.line, width: 1.4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var r = 0; r < t.rows.length; r++) ...[
              if (r > 0)
                Divider(height: 1, thickness: 1, color: paper.line),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var c = 0; c < t.rows[r].length; c++)
                      cellWidget(r, c),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
