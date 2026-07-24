import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/nd_colors.dart';
import '../../data/data_providers.dart';
import '../editor/editor_state.dart';
import '../forms/form_model.dart';
import '../forms/insert_table.dart';
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
    final formField = ref.watch(activeFormFieldProvider);

    // Yazı modunda: serbest not → Quill biçim çubuğu; form notu (Quill yok) →
    // form çubuğu (odaklı alan varsa kalın/italik/altı çizili + tablo); aksi
    // halde kalem çubuğu.
    final activeDoc = ref.watch(activeDocumentProvider);
    final isFormNote =
        activeDoc?.type == 'not' && isFormBody(activeDoc?.body ?? '');
    final isQuillText = tool == PenTool.yazi && controller != null;
    final isFormText =
        tool == PenTool.yazi && controller == null && isFormNote;
    // Lasso ile bir şey seçildiyse seçim çubuğu (sil / bırak) gösterilir.
    final selection = ref.watch(strokeSelectionProvider);
    final isLassoSel = tool == PenTool.lasso && selection.isNotEmpty;
    final Widget child = isQuillText
        ? _TextBar(controller: controller)
        : isFormText
            ? _FormTextBar(field: formField)
            : isLassoSel
                ? _LassoBar(selection: selection)
                : const _PenBar();

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
              key: ValueKey(isQuillText
                  ? 'text'
                  : isFormText
                      ? 'form'
                      : isLassoSel
                          ? 'lasso'
                          : 'pen'),
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
    final activeDoc = ref.watch(activeDocumentProvider);
    final isNote = activeDoc?.type == 'not';
    // Form notlarında Quill yok ama yine de yazı modu var (alanları düzenlemek
    // + biçim çubuğu için) → Aa düğmesi burada da görünmeli.
    final isForm = isNote && isFormBody(activeDoc?.body ?? '');
    final hasStrokes =
        (ref.watch(activeStrokesProvider).valueOrNull ?? const []).isNotEmpty;
    final canRedo = ref.watch(strokeRedoProvider).isNotEmpty;

    void setTool(PenTool t) {
      ref.read(toolProvider.notifier).state = t;
      // Lasso'dan çıkınca seçim anlamını yitirir.
      if (t != PenTool.lasso &&
          ref.read(strokeSelectionProvider).isNotEmpty) {
        ref.read(strokeSelectionProvider.notifier).state = <int>{};
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ToolButton(
          icon: Icons.pan_tool_alt_outlined,
          active: tool == PenTool.el,
          tooltip: context.t('Seç / kaydır', 'Select / pan'),
          onTap: () => setTool(PenTool.el),
        ),
        if (canText || isForm)
          _ToolButton(
            icon: Icons.text_format,
            active: false,
            tooltip: context.t('Yazı (Aa)', 'Text (Aa)'),
            onTap: () => setTool(PenTool.yazi),
          ),
        _ToolButton(
          icon: Icons.edit_outlined,
          active: tool == PenTool.kalem,
          tooltip: context.t('Kalem', 'Pen'),
          onTap: () => setTool(PenTool.kalem),
        ),
        _ToolButton(
          icon: Icons.border_color_outlined,
          active: tool == PenTool.fosfor,
          tooltip: context.t('Fosforlu kalem', 'Highlighter'),
          onTap: () => setTool(PenTool.fosfor),
        ),
        _ToolButton(
          icon: Icons.auto_fix_normal_outlined,
          active: tool == PenTool.silgi,
          tooltip: context.t('Silgi', 'Eraser'),
          onTap: () => setTool(PenTool.silgi),
        ),
        const _ShapeButton(),
        _ToolButton(
          icon: Icons.highlight_alt_outlined,
          active: tool == PenTool.lasso,
          tooltip: context.t('Kement (seç ve taşı)', 'Lasso (select & move)'),
          onTap: () => setTool(PenTool.lasso),
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
          tooltip: context.t('Geri al', 'Undo'),
          opacity: hasStrokes ? 1 : 0.35,
          onTap: docId == null || !hasStrokes
              ? null
              : () async {
                  final removed = await ref
                      .read(drawingRepositoryProvider)
                      .undoLastForDoc(docId);
                  if (removed == null) return;
                  ref.read(strokeRedoProvider.notifier).state = [
                    ...ref.read(strokeRedoProvider),
                    removed,
                  ];
                },
        ),
        _ToolButton(
          icon: Icons.redo,
          active: false,
          tooltip: context.t('İleri al', 'Redo'),
          opacity: canRedo ? 1 : 0.35,
          onTap: !canRedo
              ? null
              : () {
                  final stack = [...ref.read(strokeRedoProvider)];
                  final s = stack.removeLast();
                  ref.read(strokeRedoProvider.notifier).state = stack;
                  ref.read(drawingRepositoryProvider).restoreStroke(s);
                },
        ),
        _ToolButton(
          icon: Icons.delete_outline,
          active: false,
          tooltip: context.t('Tümünü temizle', 'Clear all'),
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
              tooltip: context.t('Çizime dön', 'Back to drawing'),
              onTap: () =>
                  ref.read(toolProvider.notifier).state = PenTool.kalem,
            ),
            _divider(nd.border),
            // Yazının geri/ileri alınması Quill'in kendi geçmişinden gelir
            // (çizim geri alma ayrı — kalem çubuğunda).
            _ToolButton(
              icon: Icons.undo,
              active: false,
              tooltip: context.t('Geri al', 'Undo'),
              opacity: controller.hasUndo ? 1 : 0.35,
              onTap: controller.hasUndo ? controller.undo : null,
            ),
            _ToolButton(
              icon: Icons.redo,
              active: false,
              tooltip: context.t('İleri al', 'Redo'),
              opacity: controller.hasRedo ? 1 : 0.35,
              onTap: controller.hasRedo ? controller.redo : null,
            ),
            _divider(nd.border),
            _ToolButton(
              icon: Icons.format_bold,
              active: _has(controller, Attribute.bold.key),
              tooltip: context.t('Kalın', 'Bold'),
              onTap: () => _toggle(Attribute.bold),
            ),
            _ToolButton(
              icon: Icons.format_italic,
              active: _has(controller, Attribute.italic.key),
              tooltip: context.t('İtalik', 'Italic'),
              onTap: () => _toggle(Attribute.italic),
            ),
            _ToolButton(
              icon: Icons.format_underlined,
              active: _has(controller, Attribute.underline.key),
              tooltip: context.t('Altı çizili', 'Underline'),
              onTap: () => _toggle(Attribute.underline),
            ),
            _ToolButton(
              icon: Icons.strikethrough_s,
              active: _has(controller, Attribute.strikeThrough.key),
              tooltip: context.t('Üstü çizili', 'Strikethrough'),
              onTap: () => _toggle(Attribute.strikeThrough),
            ),
            _divider(nd.border),
            _ToolButton(
              icon: Icons.format_list_bulleted,
              active: _has(controller, Attribute.list.key, 'bullet'),
              tooltip: context.t('Madde işareti', 'Bulleted list'),
              onTap: () => _toggleList('bullet'),
            ),
            _ToolButton(
              icon: Icons.checklist,
              active: _has(controller, Attribute.list.key, 'unchecked') ||
                  _has(controller, Attribute.list.key, 'checked'),
              tooltip: context.t('Onay kutulu liste', 'Checklist'),
              onTap: () => _toggleList('unchecked'),
            ),
            _divider(nd.border),
            _SizeButton(controller: controller),
            _FontButton(controller: controller),
            const _TableButton(),
          ],
        );
      },
    );
  }
}

/// Form notu biçim çubuğu: odaklanmış alanın tamamına kalın/italik/altı çizili
/// uygular (alan bazlı — Quill değil). Boyut/liste yok (satır yükseklikleri
/// sabit; ayrıntı form_model.dart). Alan odaklı değilken yalnızca tablo ekleme
/// ve çizime dönüş görünür.
class _FormTextBar extends ConsumerWidget {
  const _FormTextBar({required this.field});

  final ActiveFormField? field;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nd = context.nd;
    final f = field;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ToolButton(
          icon: Icons.edit_outlined,
          active: false,
          tooltip: context.t('Çizime dön', 'Back to drawing'),
          onTap: () => ref.read(toolProvider.notifier).state = PenTool.kalem,
        ),
        _divider(nd.border),
        if (f != null) ...[
          _ToolButton(
            icon: Icons.format_bold,
            active: f.flags.contains(kFmtBold),
            tooltip: context.t('Kalın', 'Bold'),
            onTap: () => f.toggle(kFmtBold),
          ),
          _ToolButton(
            icon: Icons.format_italic,
            active: f.flags.contains(kFmtItalic),
            tooltip: context.t('İtalik', 'Italic'),
            onTap: () => f.toggle(kFmtItalic),
          ),
          _ToolButton(
            icon: Icons.format_underlined,
            active: f.flags.contains(kFmtUnderline),
            tooltip: context.t('Altı çizili', 'Underline'),
            onTap: () => f.toggle(kFmtUnderline),
          ),
          _divider(nd.border),
          // Odaklı alan bir tablo hücresiyse satır/sütun düzenleme menüsü.
          if (f.tableMenu != null)
            _ToolButton(
              icon: Icons.border_all,
              active: false,
              tooltip: context.t('Satır / sütun düzenle', 'Edit rows / columns'),
              onTap: f.tableMenu,
            ),
        ],
        const _TableButton(),
      ],
    );
  }
}

/// Tablo ekleme düğmesi (yazı modu). Editör kancayı kurmuşsa görünür.
class _TableButton extends ConsumerWidget {
  const _TableButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(tableInserterProvider) == null) return const SizedBox.shrink();
    return _ToolButton(
      icon: Icons.grid_on,
      active: false,
      tooltip: context.t('Tablo ekle', 'Add table'),
      onTap: () => showInsertTableDialog(context, ref),
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
        message: context.t('Yazı tipi', 'Font'),
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

/// Kement ile bir şey seçildiğinde görünen çubuk: kaç çizim seçili, sil, bırak.
/// Taşıma çubuktan değil, seçim çerçevesini parmakla sürükleyerek yapılır.
class _LassoBar extends ConsumerWidget {
  const _LassoBar({required this.selection});

  final Set<int> selection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nd = context.nd;
    final docId = ref.watch(navProvider).activeDocId;

    void clear() =>
        ref.read(strokeSelectionProvider.notifier).state = <int>{};

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ToolButton(
          icon: Icons.edit_outlined,
          active: false,
          tooltip: context.t('Çizime dön', 'Back to drawing'),
          onTap: () {
            clear();
            ref.read(toolProvider.notifier).state = PenTool.kalem;
          },
        ),
        _divider(nd.border),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            context.t('${selection.length} seçili',
                '${selection.length} selected'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        _ToolButton(
          icon: Icons.delete_outline,
          active: false,
          tooltip: context.t('Seçili çizimleri sil', 'Delete selected drawings'),
          onTap: docId == null
              ? null
              : () async {
                  await ref
                      .read(drawingRepositoryProvider)
                      .deleteStrokes(selection);
                  clear();
                },
        ),
        _ToolButton(
          icon: Icons.close,
          active: false,
          tooltip: context.t('Seçimi bırak', 'Clear selection'),
          onTap: clear,
        ),
      ],
    );
  }
}

/// Kalem/fosfor ile düz çizgi, dikdörtgen veya elips çizme modu seçici. Düğme
/// mevcut şekli gösterir (bir şekil seçiliyse vurgulu); dokununca menü açılır.
class _ShapeButton extends ConsumerWidget {
  const _ShapeButton();

  IconData _icon(ShapeMode m) => switch (m) {
        ShapeMode.serbest => Icons.gesture,
        ShapeMode.cizgi => Icons.horizontal_rule,
        ShapeMode.dikdortgen => Icons.crop_square,
        ShapeMode.elips => Icons.circle_outlined,
      };

  String _label(BuildContext c, ShapeMode m) => switch (m) {
        ShapeMode.serbest => c.t('Serbest çizim', 'Freehand'),
        ShapeMode.cizgi => c.t('Düz çizgi', 'Straight line'),
        ShapeMode.dikdortgen => c.t('Dikdörtgen', 'Rectangle'),
        ShapeMode.elips => c.t('Elips', 'Ellipse'),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nd = context.nd;
    final mode = ref.watch(shapeModeProvider);
    final active = mode != ShapeMode.serbest;
    return PopupMenuButton<ShapeMode>(
      tooltip: context.t('Şekil', 'Shape'),
      color: nd.card,
      position: PopupMenuPosition.under,
      onSelected: (m) => ref.read(shapeModeProvider.notifier).state = m,
      itemBuilder: (context) => [
        for (final m in ShapeMode.values)
          PopupMenuItem(
            value: m,
            child: Row(
              children: [
                Icon(_icon(m),
                    size: 18, color: m == mode ? nd.accent : nd.text2),
                const SizedBox(width: 12),
                Text(_label(context, m),
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight:
                            m == mode ? FontWeight.w600 : FontWeight.w400,
                        color: m == mode ? nd.text : nd.text2)),
              ],
            ),
          ),
      ],
      child: Material(
        color: active ? nd.accent : Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(active ? _icon(mode) : Icons.category_outlined,
              size: 18, color: active ? nd.accentFg : nd.text2),
        ),
      ),
    );
  }
}

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
        message: context.t('Kağıt rengi', 'Paper colour'),
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
        message: context.t('Yazı boyutu', 'Text size'),
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
