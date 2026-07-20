import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/nd_colors.dart';
import '../../data/data_providers.dart';
import '../editor/editor_state.dart';
import '../shell/shell_state.dart';
import 'color_picker.dart';
import 'drawing_state.dart';

/// Kağıt rengi adının İngilizcesi (menüde gösterim için).
String _paperLabelEn(String id) => switch (id) {
      'beyaz' => 'White',
      'sari' => 'Yellow',
      'yesil' => 'Green',
      'siyah' => 'Black',
      _ => id,
    };

/// Not/PDF ekranının altındaki araç çubuğu. Yazı modunda (Aa) metin
/// biçimlendirme, çizim modunda kalem araçlarını gösterir.
class DrawingToolbar extends ConsumerWidget {
  const DrawingToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nd = context.nd;
    final tool = ref.watch(toolProvider);
    final controller = ref.watch(activeQuillControllerProvider);

    final isText = tool == PenTool.yazi && controller != null;
    final Widget child =
        isText ? _TextBar(controller: controller) : const _PenBar();

    // Araç çubuğuna dokununca editörün odağı (klavye) kapanmasın; böylece
    // biçimlendirme ve font seçimi imleci koruyup sonraki yazıya da uygulanır.
    return TextFieldTapRegion(
      child: Container(
      // Yuvarlak çerçeveye kırp; animasyon sırasında ikonlar köşeli taşmasın.
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: nd.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: nd.border),
        boxShadow: nd.shadow,
      ),
      padding: const EdgeInsets.all(5),
      // Önce arka plan (genişlik) animasyonla değişir, sonra ikonlar sıra ile
      // gelir: eski ikonlar ilk %40'ta solar, yenileri %45'ten sonra belirir.
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        clipBehavior: Clip.none,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: const Interval(0.45, 1.0, curve: Curves.easeOut),
            switchOutCurve: const Interval(0.0, 0.4, curve: Curves.easeIn),
            transitionBuilder: (c, anim) =>
                FadeTransition(opacity: anim, child: c),
            child: KeyedSubtree(
              key: ValueKey(isText ? 'text' : 'pen'),
              child: child,
            ),
          ),
        ),
      ),
      ),
    );
  }
}

// ─────────────────────────── Çizim araçları ───────────────────────────

class _PenBar extends ConsumerWidget {
  const _PenBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nd = context.nd;
    final tool = ref.watch(toolProvider);
    final inkIndex = ref.watch(inkIndexProvider);
    final sizeIndex = ref.watch(sizeIndexProvider);
    final docId = ref.watch(navProvider).activeDocId;
    final canText = ref.watch(activeQuillControllerProvider) != null;
    final palette = ref.watch(penPaletteProvider);
    final isNote = ref.watch(activeDocumentProvider)?.type == 'not';
    final hasStrokes =
        (ref.watch(activeStrokesProvider).valueOrNull ?? const []).isNotEmpty;

    void setTool(PenTool t) => ref.read(toolProvider.notifier).state = t;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ToolButton(
          icon: Icons.pan_tool_alt_outlined,
          active: tool == PenTool.el,
          tooltip: 'Seç / kaydır',
          onTap: () => setTool(PenTool.el),
        ),
        if (canText)
          _ToolButton(
            icon: Icons.text_format,
            active: false,
            tooltip: 'Yazı (Aa)',
            onTap: () => setTool(PenTool.yazi),
          ),
        _ToolButton(
          icon: Icons.edit_outlined,
          active: tool == PenTool.kalem,
          tooltip: 'Kalem',
          onTap: () => setTool(PenTool.kalem),
        ),
        _ToolButton(
          icon: Icons.border_color_outlined,
          active: tool == PenTool.fosfor,
          tooltip: 'Fosforlu kalem',
          onTap: () => setTool(PenTool.fosfor),
        ),
        _ToolButton(
          icon: Icons.auto_fix_normal_outlined,
          active: tool == PenTool.silgi,
          tooltip: 'Silgi',
          onTap: () => setTool(PenTool.silgi),
        ),
        _divider(nd.border),
        // 3 sabit renk (ayarlardan seçilir); son yuva "rengarenk" → paletten.
        for (var i = 0; i < palette.length; i++)
          _ColorDot(
            color: palette[i],
            selected: inkIndex == i,
            onTap: () => ref.read(inkIndexProvider.notifier).state = i,
          ),
        _RainbowDot(index: palette.length),
        _divider(nd.border),
        for (var i = 0; i < kStrokeSizes.length; i++)
          _SizeDot(
            dot: [4.0, 7.0, 10.0][i],
            active: sizeIndex == i,
            onTap: () => ref.read(sizeIndexProvider.notifier).state = i,
          ),
        // Kağıt rengi yalnızca notlarda anlamlı (PDF'te sadece çizim).
        if (isNote) ...[
          _divider(nd.border),
          _PaperButton(docId: docId),
        ],
        _divider(nd.border),
        _ToolButton(
          icon: Icons.undo,
          active: false,
          tooltip: 'Geri al',
          opacity: hasStrokes ? 1 : 0.35,
          onTap: docId == null || !hasStrokes
              ? null
              : () => ref.read(drawingRepositoryProvider).undoLastForDoc(docId),
        ),
        _ToolButton(
          icon: Icons.delete_outline,
          active: false,
          tooltip: 'Tümünü temizle',
          opacity: hasStrokes ? 1 : 0.35,
          onTap: docId == null || !hasStrokes
              ? null
              : () => ref.read(drawingRepositoryProvider).clearDoc(docId),
        ),
      ],
    );
  }
}

// ─────────────────────────── Metin araçları ───────────────────────────

class _TextBar extends ConsumerWidget {
  const _TextBar({required this.controller});

  final QuillController controller;

  bool _has(QuillController c, String key, [String? value]) {
    final attrs = c.getSelectionStyle().attributes;
    if (!attrs.containsKey(key)) return false;
    if (value == null) return true;
    return attrs[key]!.value == value;
  }

  void _toggle(Attribute attr) {
    final isSet = controller.getSelectionStyle().attributes.containsKey(attr.key);
    controller.formatSelection(isSet ? Attribute.clone(attr, null) : attr);
  }

  void _toggleList(String value) {
    final active = _has(controller, Attribute.list.key, value);
    controller.formatSelection(
      active ? Attribute.clone(Attribute.list, null) : Attribute.fromKeyValue('list', value),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nd = context.nd;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToolButton(
              icon: Icons.edit_outlined,
              active: false,
              tooltip: 'Çizime dön',
              onTap: () =>
                  ref.read(toolProvider.notifier).state = PenTool.kalem,
            ),
            _divider(nd.border),
            _ToolButton(
              icon: Icons.format_bold,
              active: _has(controller, Attribute.bold.key),
              tooltip: 'Kalın',
              onTap: () => _toggle(Attribute.bold),
            ),
            _ToolButton(
              icon: Icons.format_italic,
              active: _has(controller, Attribute.italic.key),
              tooltip: 'İtalik',
              onTap: () => _toggle(Attribute.italic),
            ),
            _ToolButton(
              icon: Icons.format_underlined,
              active: _has(controller, Attribute.underline.key),
              tooltip: 'Altı çizili',
              onTap: () => _toggle(Attribute.underline),
            ),
            _ToolButton(
              icon: Icons.strikethrough_s,
              active: _has(controller, Attribute.strikeThrough.key),
              tooltip: 'Üstü çizili',
              onTap: () => _toggle(Attribute.strikeThrough),
            ),
            _divider(nd.border),
            _ToolButton(
              icon: Icons.format_list_bulleted,
              active: _has(controller, Attribute.list.key, 'bullet'),
              tooltip: 'Madde işareti',
              onTap: () => _toggleList('bullet'),
            ),
            _ToolButton(
              icon: Icons.checklist,
              active: _has(controller, Attribute.list.key, 'unchecked') ||
                  _has(controller, Attribute.list.key, 'checked'),
              tooltip: 'Onay kutulu liste',
              onTap: () => _toggleList('unchecked'),
            ),
            _divider(nd.border),
            _SizeButton(controller: controller),
            _FontButton(controller: controller),
          ],
        );
      },
    );
  }
}

class _FontButton extends StatefulWidget {
  const _FontButton({required this.controller});

  final QuillController controller;

  @override
  State<_FontButton> createState() => _FontButtonState();
}

class _FontButtonState extends State<_FontButton> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;

  @override
  void dispose() {
    _remove();
    super.dispose();
  }

  void _remove() {
    _entry?.remove();
    _entry = null;
  }

  void _apply(String family) {
    widget.controller.formatSelection(Attribute.fromKeyValue('font', family));
    _remove();
  }

  void _toggle() {
    if (_entry != null) {
      _remove();
      return;
    }
    final nd = context.nd;
    // Buton üzerinde YUKARI doğru açılan liste. Overlay odağı çalmaz →
    // klavye/imleç korunur → seçilen font sonraki yazıya da uygulanır.
    _entry = OverlayEntry(
      builder: (context) => TextFieldTapRegion(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _remove,
              ),
            ),
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              targetAnchor: Alignment.topCenter,
              followerAnchor: Alignment.bottomCenter,
              offset: const Offset(0, -8),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 200,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: nd.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: nd.border),
                    boxShadow: nd.shadow,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final entry in kNoteFonts.entries)
                        InkWell(
                          onTap: () => _apply(entry.value),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                entry.key,
                                style: TextStyle(
                                    fontFamily: entry.value,
                                    fontSize: 15,
                                    color: nd.text),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    Overlay.of(context).insert(_entry!);
  }

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    return CompositedTransformTarget(
      link: _link,
      child: Tooltip(
        message: 'Yazı tipi',
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _toggle,
            child: SizedBox(
              width: 42,
              height: 36,
              child: Icon(Icons.font_download_outlined,
                  size: 18, color: nd.text2),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Ortak parçalar ───────────────────────────

Widget _divider(Color color) => Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      color: color,
    );

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.active,
    required this.tooltip,
    this.onTap,
    this.opacity = 1,
  });

  final IconData icon;
  final bool active;
  final String tooltip;
  final VoidCallback? onTap;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: opacity,
        child: Material(
          color: active ? nd.accent : Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(icon,
                  size: 18, color: active ? nd.accentFg : nd.text2),
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? nd.text : Colors.black.withValues(alpha: 0.12),
            width: selected ? 2.5 : 1,
          ),
        ),
      ),
    );
  }
}

class _SizeDot extends StatelessWidget {
  const _SizeDot({required this.dot, required this.active, required this.onTap});

  final double dot;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? nd.accent : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Container(
          width: dot,
          height: dot,
          decoration: BoxDecoration(
            color: active ? nd.accentFg : nd.text2,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────── Rengarenk (palet) renk yuvası ───────────────────────

/// 4. renk yuvası: "rengarenk". Dokununca ortak renk paleti (dialog) açılır;
/// seçilen renk hem bu yuvada kullanılır hem de yuvada gösterilir.
class _RainbowDot extends ConsumerWidget {
  const _RainbowDot({required this.index});

  final int index;

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    ref.read(inkIndexProvider.notifier).state = index;
    final picked = await showColorGridDialog(
      context,
      current: ref.read(customInkColorProvider),
    );
    if (picked != null) {
      ref.read(customInkColorProvider.notifier).state = picked;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nd = context.nd;
    final selected = ref.watch(inkIndexProvider) == index;
    final custom = ref.watch(customInkColorProvider);
    return GestureDetector(
      onTap: () => _open(context, ref),
      child: Container(
        width: 24,
        height: 24,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const SweepGradient(colors: [
            Color(0xFFE0533D),
            Color(0xFFF0B429),
            Color(0xFF16A34A),
            Color(0xFF22D3EE),
            Color(0xFF4A6CF7),
            Color(0xFF7C3AED),
            Color(0xFFDB2777),
            Color(0xFFE0533D),
          ]),
          border: Border.all(
            color: selected ? nd.text : Colors.black.withValues(alpha: 0.12),
            width: selected ? 2.5 : 1,
          ),
        ),
        child: selected
            ? Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: custom,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

// ─────────────────────────── Kağıt (sayfa) rengi ───────────────────────────

/// Kağıt rengini seçmek için temiz, dikey menü (yalnızca notlarda görünür).
class _PaperButton extends ConsumerStatefulWidget {
  const _PaperButton({required this.docId});

  final int? docId;

  @override
  ConsumerState<_PaperButton> createState() => _PaperButtonState();
}

class _PaperButtonState extends ConsumerState<_PaperButton> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;

  @override
  void dispose() {
    _remove();
    super.dispose();
  }

  void _remove() {
    _entry?.remove();
    _entry = null;
  }

  void _set(String id) {
    final docId = widget.docId;
    if (docId != null) {
      ref
          .read(documentRepositoryProvider)
          .setPageColor(id: docId, pageColor: id);
    }
    _remove();
  }

  void _setBg(String id) {
    final docId = widget.docId;
    if (docId != null) {
      ref
          .read(documentRepositoryProvider)
          .setPageBackground(id: docId, value: id);
    }
    _remove();
  }

  void _open() {
    if (_entry != null) {
      _remove();
      return;
    }
    if (widget.docId == null) return;
    final nd = context.nd;
    final current = ref.read(activeDocumentProvider)?.pageColor ?? 'beyaz';
    final currentBg =
        ref.read(activeDocumentProvider)?.pageBackground ?? 'duz';
    _entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _remove,
            ),
          ),
          CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            targetAnchor: Alignment.topCenter,
            followerAnchor: Alignment.bottomCenter,
            offset: const Offset(0, -10),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 180,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: nd.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: nd.border),
                  boxShadow: nd.shadow,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 420),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final p in kPaperStyles)
                          InkWell(
                            onTap: () => _set(p.id),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: p.background,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: nd.border),
                                    ),
                                    child: Text('A',
                                        style: TextStyle(
                                            color: p.text,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                        context.isEn
                                            ? _paperLabelEn(p.id)
                                            : p.label,
                                        style: TextStyle(
                                            fontSize: 14, color: nd.text)),
                                  ),
                                  if (p.id == current)
                                    Icon(Icons.check,
                                        size: 16, color: nd.text),
                                ],
                              ),
                            ),
                          ),
                        Divider(height: 1, color: nd.border),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 9, 14, 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              context.t('Sayfa deseni', 'Page pattern'),
                              style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: nd.text2),
                            ),
                          ),
                        ),
                        for (final b in kPageBackgrounds)
                          InkWell(
                            onTap: () => _setBg(b.id),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  Icon(b.icon, size: 20, color: nd.text2),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(context.isEn ? b.en : b.tr,
                                        style: TextStyle(
                                            fontSize: 14, color: nd.text)),
                                  ),
                                  if (b.id == currentBg)
                                    Icon(Icons.check,
                                        size: 16, color: nd.text),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_entry!);
  }

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    return CompositedTransformTarget(
      link: _link,
      child: Tooltip(
        message: 'Kağıt rengi',
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.docId == null ? null : _open,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(Icons.format_color_fill,
                  size: 18, color: nd.text2),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────── Yazı boyutu ───────────────────────────────

class _SizeButton extends StatefulWidget {
  const _SizeButton({required this.controller});

  final QuillController controller;

  @override
  State<_SizeButton> createState() => _SizeButtonState();
}

class _SizeButtonState extends State<_SizeButton> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;

  @override
  void dispose() {
    _remove();
    super.dispose();
  }

  void _remove() {
    _entry?.remove();
    _entry = null;
  }

  void _apply(double? size) {
    if (size == null) {
      widget.controller.formatSelection(Attribute.clone(Attribute.size, null));
    } else {
      widget.controller
          .formatSelection(Attribute.fromKeyValue('size', size.toInt().toString()));
    }
    _remove();
  }

  void _toggle() {
    if (_entry != null) {
      _remove();
      return;
    }
    final nd = context.nd;
    _entry = OverlayEntry(
      builder: (context) => TextFieldTapRegion(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _remove,
              ),
            ),
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              targetAnchor: Alignment.topCenter,
              followerAnchor: Alignment.bottomCenter,
              offset: const Offset(0, -8),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 150,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: nd.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: nd.border),
                    boxShadow: nd.shadow,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _item('Otomatik', null, 15, nd),
                      for (final s in kFontSizes)
                        _item('${s.toInt()} punto', s,
                            s.clamp(12, 22).toDouble(), nd),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    Overlay.of(context).insert(_entry!);
  }

  Widget _item(String label, double? size, double preview, NdColors nd) =>
      InkWell(
        onTap: () => _apply(size),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(label,
                style: TextStyle(fontSize: preview, color: nd.text)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    return CompositedTransformTarget(
      link: _link,
      child: Tooltip(
        message: 'Yazı boyutu',
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _toggle,
            child: SizedBox(
              width: 42,
              height: 36,
              child: Icon(Icons.format_size, size: 18, color: nd.text2),
            ),
          ),
        ),
      ),
    );
  }
}
