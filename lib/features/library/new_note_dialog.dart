import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/nd_colors.dart';
import '../../data/data_providers.dart';
import '../../data/database/database.dart';
import '../editor/editor_state.dart';
import '../shell/actions.dart';
import '../templates/templates_data.dart';

/// Yeni not diyaloğunu açar (ad + sayfa boyutu + kağıt rengi + şablon ızgarası).
/// Seçime göre notu oluşturup editörde açar; kullanıcı iptal ederse bir şey yapmaz.
Future<void> showNewNoteDialog(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _NewNoteDialog(),
  );
}

class _NewNoteDialog extends ConsumerStatefulWidget {
  const _NewNoteDialog();

  @override
  ConsumerState<_NewNoteDialog> createState() => _NewNoteDialogState();
}

class _NewNoteDialogState extends ConsumerState<_NewNoteDialog> {
  final _name = TextEditingController();
  String _pageSize = 'a4';
  String _pageColor = 'beyaz';
  String _pageBackground = 'duz';
  String _category = 'temel';
  // 'blank' | 'builtin:<id>' | 'user:<id>'
  String _selectedKey = 'blank';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _selectBuiltIn(NoteTemplate t) {
    setState(() {
      _selectedKey = 'builtin:${t.id}';
      _pageSize = t.pageSize;
      _pageColor = t.pageColor;
      _pageBackground = t.pageBackground;
    });
  }

  void _selectUser(Template t) {
    setState(() {
      _selectedKey = 'user:${t.id}';
      _pageSize = t.pageSize;
      _pageColor = t.pageColor;
      _pageBackground = t.pageBackground;
    });
  }

  Future<void> _create() async {
    final en = context.isEn;
    String body = '';
    String strokes = '[]';
    if (_selectedKey.startsWith('builtin:')) {
      final id = _selectedKey.substring(8);
      final t = kBuiltInTemplates.firstWhere((e) => e.id == id,
          orElse: () => kBuiltInTemplates.first);
      body = t.body(en);
    } else if (_selectedKey.startsWith('user:')) {
      final id = int.tryParse(_selectedKey.substring(5));
      final list = ref.read(userTemplatesProvider).valueOrNull ?? const [];
      Template? t;
      for (final e in list) {
        if (e.id == id) {
          t = e;
          break;
        }
      }
      if (t != null) {
        body = t.body;
        strokes = t.strokes;
      }
    }
    await createConfiguredNote(
      ref,
      title: _name.text.trim(),
      pageSize: _pageSize,
      pageColor: _pageColor,
      pageBackground: _pageBackground,
      body: body,
      strokesJson: strokes,
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _deleteUserTemplate(Template t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t('Şablon silinsin mi?', 'Delete template?')),
        content: Text(t.title.isEmpty
            ? context.t('Bu şablon silinecek.', 'This template will be deleted.')
            : '"${t.title}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.t('Vazgeç', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.t('Sil', 'Delete')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(templateRepositoryProvider).delete(t.id);
    if (_selectedKey == 'user:${t.id}') {
      setState(() => _selectedKey = 'blank');
    }
  }

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    final en = context.isEn;
    final screenH = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: nd.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        // Sabit yükseklik → sekme (kategori) değişince şablon sayısı farklı olsa
        // bile pop-up boyutu oynamaz; içerik Flexible içindeki kaydırmayla akar.
        child: SizedBox(
          height: (screenH * 0.82).clamp(420.0, 640.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.t('Yeni not', 'New note'),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Not adı
                    TextField(
                      controller: _name,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: context.t(
                            'Not adı (isteğe bağlı)', 'Note name (optional)'),
                        filled: true,
                        fillColor: nd.bg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: nd.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: nd.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _label(context, context.t('Sayfa', 'Page')),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final p in kPageSizes)
                          _SizeChip(
                            option: p,
                            selected: _pageSize == p.id,
                            en: en,
                            onTap: () => setState(() => _pageSize = p.id),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _label(context, context.t('Kağıt', 'Paper')),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final s in kPaperStyles)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: _ColorDot(
                              style: s,
                              selected: _pageColor == s.id,
                              onTap: () =>
                                  setState(() => _pageColor = s.id),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _label(context, context.t('Şablon', 'Template')),
                    const SizedBox(height: 8),
                    // Kategori sekmeleri
                    SizedBox(
                      height: 34,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final c in kTemplateCategories)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _CategoryChip(
                                label: en ? c.en : c.tr,
                                selected: _category == c.key,
                                onTap: () =>
                                    setState(() => _category = c.key),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _grid(context, en),
                  ],
                ),
              ),
            ),
            // Oluştur
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _create,
                  child: Text(context.t('Oluştur', 'Create')),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _grid(BuildContext context, bool en) {
    final tiles = <Widget>[];

    // 'Temel' sekmesinde boş sayfa + kâğıt desenleri (düz/çizgili/kareli/noktalı)
    // — hepsi o an seçili boyut/renkte boş bir not açar.
    if (_category == 'temel') {
      const blanks = [
        ('duz', 'Boş sayfa', 'Blank page'),
        ('cizgili', 'Çizgili', 'Lined'),
        ('kareli', 'Kareli', 'Grid'),
        ('noktali', 'Noktalı', 'Dotted'),
      ];
      for (final (bg, tr, en2) in blanks) {
        tiles.add(_TemplateTile(
          label: context.t(tr, en2),
          body: '',
          pageSize: _pageSize,
          pageColor: _pageColor,
          pageBackground: bg,
          selected: _selectedKey == 'blank' && _pageBackground == bg,
          onTap: () => setState(() {
            _selectedKey = 'blank';
            _pageBackground = bg;
          }),
        ));
      }
    }

    if (_category == 'benim') {
      final userTemplates =
          ref.watch(userTemplatesProvider).valueOrNull ?? const [];
      if (userTemplates.isEmpty) {
        return _emptyMyTemplates(context);
      }
      for (final t in userTemplates) {
        tiles.add(_TemplateTile(
          label: t.title.isEmpty ? context.t('Adsız', 'Untitled') : t.title,
          body: t.body,
          pageSize: t.pageSize,
          pageColor: t.pageColor,
          pageBackground: t.pageBackground,
          selected: _selectedKey == 'user:${t.id}',
          onTap: () => _selectUser(t),
          onLongPress: () => _deleteUserTemplate(t),
        ));
      }
    } else {
      for (final t
          in kBuiltInTemplates.where((e) => e.category == _category)) {
        tiles.add(_TemplateTile(
          label: t.name(en),
          body: t.body(en),
          pageSize: t.pageSize,
          pageColor: t.pageColor,
          pageBackground: t.pageBackground,
          selected: _selectedKey == 'builtin:${t.id}',
          onTap: () => _selectBuiltIn(t),
        ));
      }
    }

    return Wrap(spacing: 12, runSpacing: 14, children: tiles);
  }

  Widget _emptyMyTemplates(BuildContext context) {
    final nd = context.nd;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
      decoration: BoxDecoration(
        color: nd.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: nd.border),
      ),
      child: Column(
        children: [
          Icon(Icons.bookmark_add_outlined, color: nd.text2, size: 26),
          const SizedBox(height: 8),
          Text(
            context.t(
                'Henüz şablon yok. Bir not açıp menüden\n"Şablon olarak kaydet" ile ekleyin.',
                'No templates yet. Open a note and use\n"Save as template" from its menu.'),
            textAlign: TextAlign.center,
            style: TextStyle(color: nd.text2, fontSize: 12.5, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Text(
        text,
        style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: context.nd.text2),
      );
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({
    required this.option,
    required this.selected,
    required this.en,
    required this.onTap,
  });

  final PageSizeOption option;
  final bool selected;
  final bool en;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? nd.accent.withValues(alpha: 0.12) : nd.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? nd.accent : nd.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(option.icon,
                size: 18, color: selected ? nd.accent : nd.text2),
            const SizedBox(width: 6),
            Text(
              en ? option.en : option.tr,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? nd.accent : nd.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final PaperStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: style.background,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? nd.accent : nd.borderStrong,
            width: selected ? 2.4 : 1,
          ),
        ),
        child: selected
            ? Icon(Icons.check,
                size: 16,
                color: style.isDark ? Colors.white : const Color(0xFF262626))
            : null,
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? nd.accent : nd.bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? nd.accent : nd.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? nd.accentFg : nd.text2,
          ),
        ),
      ),
    );
  }
}

/// Şablon kartı: üstte gerçek sayfa önizlemesi (boyut + kâğıt rengi + desen +
/// içeriğin şematiği), altta ad.
class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.label,
    required this.body,
    required this.pageSize,
    required this.pageColor,
    required this.pageBackground,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  final String label;
  final String body;
  final String pageSize;
  final String pageColor;
  final String pageBackground;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    // Küçük tutulur: dar telefonda bile satıra 3 kart sığar.
    const tileW = 84.0;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: tileW,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: tileW,
              height: 82,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? nd.accent.withValues(alpha: 0.10) : nd.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? nd.accent : nd.border,
                  width: selected ? 1.6 : 1,
                ),
              ),
              child: _TemplatePreview(
                body: body,
                pageSize: pageSize,
                pageColor: pageColor,
                pageBackground: pageBackground,
                boxWidth: tileW - 18,
                boxHeight: 66,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.15,
                fontWeight: FontWeight.w600,
                color: nd.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bir şablonun küçük sayfa önizlemesi (doğru en/boy oranı + kâğıt rengi +
/// arka plan deseni + içeriğin şematik satırları).
class _TemplatePreview extends StatelessWidget {
  const _TemplatePreview({
    required this.body,
    required this.pageSize,
    required this.pageColor,
    required this.pageBackground,
    required this.boxWidth,
    required this.boxHeight,
  });

  final String body;
  final String pageSize;
  final String pageColor;
  final String pageBackground;
  final double boxWidth;
  final double boxHeight;

  @override
  Widget build(BuildContext context) {
    final aspect = aspectForPageSize(pageSize);
    double pageH = boxHeight;
    double pageW = pageH / aspect;
    if (pageW > boxWidth) {
      pageW = boxWidth;
      pageH = pageW * aspect;
    }
    final paper = paperStyleFor(pageColor);
    return Container(
      width: pageW,
      height: pageH,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: paper.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0x22000000), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _PreviewPainter(body, pageBackground, paper),
        size: Size(pageW, pageH),
      ),
    );
  }
}

enum _PL { title, heading, label, para, bullet, check, table }

/// Şablon gövdesini (Quill Delta veya form-not) şematik satır tiplerine
/// ayırır — önizleme için.
List<_PL> _previewLines(String body) {
  final out = <_PL>[];
  dynamic data;
  try {
    data = jsonDecode(body);
  } catch (_) {
    data = null;
  }
  // Form-not: blok tipleri doğrudan şematiğe çevrilir.
  if (data is Map && data['ndform'] == 1) {
    for (final raw in (data['blocks'] as List? ?? const [])) {
      if (raw is! Map) continue;
      switch (raw['type']) {
        case 'title':
          out.add(_PL.title);
        case 'label':
          out.add(_PL.label);
        case 'fields':
          out.add(_PL.para);
        case 'check':
          final n = (raw['i'] as List?)?.length ?? 2;
          for (var k = 0; k < (n > 3 ? 3 : n); k++) {
            out.add(_PL.check);
          }
        case 'num':
          final n = (raw['i'] as List?)?.length ?? 2;
          for (var k = 0; k < (n > 3 ? 3 : n); k++) {
            out.add(_PL.bullet);
          }
        case 'area':
          out.addAll([_PL.para, _PL.para]);
        case 'mood':
          out.add(_PL.para);
        case 'hours':
        case 'week':
        case 'cornell':
          out.add(_PL.table);
        case 'sketch':
          out.add(_PL.table);
      }
    }
    return out;
  }
  if (data is! List) return out;
  double? size;
  for (final op in data) {
    if (op is! Map) continue;
    final ins = op['insert'];
    if (ins is Map) {
      if (ins.containsKey('ndtable')) out.add(_PL.table);
      continue;
    }
    if (ins is! String) continue;
    final attrs = (op['attributes'] as Map?) ?? const {};
    final parts = ins.split('\n');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        final s = attrs['size'];
        if (s != null) size = double.tryParse(s.toString());
      }
      if (i < parts.length - 1) {
        final list = attrs['list'];
        _PL type;
        if (list == 'bullet') {
          type = _PL.bullet;
        } else if (list == 'checked' || list == 'unchecked') {
          type = _PL.check;
        } else if (size != null && size >= 22) {
          type = _PL.title;
        } else if (size != null && size >= 17) {
          type = _PL.heading;
        } else if (size != null && size <= 13) {
          type = _PL.label;
        } else {
          type = _PL.para;
        }
        out.add(type);
        size = null;
      }
    }
  }
  return out;
}

class _PreviewPainter extends CustomPainter {
  _PreviewPainter(this.body, this.background, this.paper);

  final String body;
  final String background;
  final PaperStyle paper;

  @override
  void paint(Canvas canvas, Size size) {
    paintPageBackground(canvas, size, background, paper.line);

    final lines = _previewLines(body);
    if (lines.isEmpty) return;

    final pad = size.width * 0.13;
    final innerW = size.width - pad * 2;
    final rowH = size.height / 12.0;
    final ink = paper.text;
    var y = pad * 0.9;

    void bar(double x, double w, double h, Color c, {double radius = 1}) {
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y - h / 2, w, h),
        Radius.circular(radius),
      );
      canvas.drawRRect(r, Paint()..color = c);
    }

    for (final ln in lines) {
      if (y > size.height - pad * 0.6) break;
      switch (ln) {
        case _PL.title:
          bar(pad, innerW * 0.62, 3.4, ink.withValues(alpha: 0.85));
        case _PL.heading:
          bar(pad, innerW * 0.5, 2.8, ink.withValues(alpha: 0.7));
        case _PL.label:
          bar(pad, innerW * 0.32, 2.0, paper.muted);
        case _PL.para:
          bar(pad, innerW * 0.9, 1.8, ink.withValues(alpha: 0.22));
        case _PL.bullet:
          canvas.drawCircle(
              Offset(pad + 2, y), 1.5, Paint()..color = ink.withValues(alpha: 0.5));
          bar(pad + 8, innerW * 0.72, 1.8, ink.withValues(alpha: 0.28));
        case _PL.check:
          final box = Rect.fromLTWH(pad, y - 3, 6, 6);
          canvas.drawRRect(
            RRect.fromRectAndRadius(box, const Radius.circular(1.5)),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = paper.muted,
          );
          bar(pad + 11, innerW * 0.72, 1.8, ink.withValues(alpha: 0.28));
        case _PL.table:
          // Tablo şematiği: 2 satırlık küçük ızgara.
          final gh = rowH * 1.9;
          final rect = Rect.fromLTWH(pad, y - rowH * 0.35, innerW, gh);
          final gp = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8
            ..color = paper.muted.withValues(alpha: 0.7);
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(1.5)),
            gp,
          );
          canvas.drawLine(Offset(rect.left, rect.center.dy),
              Offset(rect.right, rect.center.dy), gp);
          canvas.drawLine(Offset(rect.left + innerW / 3, rect.top),
              Offset(rect.left + innerW / 3, rect.bottom), gp);
          canvas.drawLine(Offset(rect.left + innerW * 2 / 3, rect.top),
              Offset(rect.left + innerW * 2 / 3, rect.bottom), gp);
          y += gh - rowH * 0.65;
      }
      y += rowH;
    }
  }

  @override
  bool shouldRepaint(_PreviewPainter old) =>
      old.body != body ||
      old.background != background ||
      old.paper.id != paper.id;
}
