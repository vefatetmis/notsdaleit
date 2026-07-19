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
    });
  }

  void _selectUser(Template t) {
    setState(() {
      _selectedKey = 'user:${t.id}';
      _pageSize = t.pageSize;
      _pageColor = t.pageColor;
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
        constraints: BoxConstraints(maxWidth: 460, maxHeight: screenH * 0.86),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
    );
  }

  Widget _grid(BuildContext context, bool en) {
    final tiles = <Widget>[];

    // 'Temel' sekmesinde ilk kutu = boş sayfa.
    if (_category == 'temel') {
      tiles.add(_TemplateTile(
        icon: Icons.insert_drive_file_outlined,
        label: context.t('Boş sayfa', 'Blank page'),
        selected: _selectedKey == 'blank',
        onTap: () => setState(() => _selectedKey = 'blank'),
      ));
    }

    if (_category == 'benim') {
      final userTemplates =
          ref.watch(userTemplatesProvider).valueOrNull ?? const [];
      if (userTemplates.isEmpty) {
        return _emptyMyTemplates(context);
      }
      for (final t in userTemplates) {
        tiles.add(_TemplateTile(
          icon: Icons.bookmark_outline_rounded,
          label: t.title.isEmpty ? context.t('Adsız', 'Untitled') : t.title,
          selected: _selectedKey == 'user:${t.id}',
          onTap: () => _selectUser(t),
          onLongPress: () => _deleteUserTemplate(t),
        ));
      }
    } else {
      for (final t
          in kBuiltInTemplates.where((e) => e.category == _category)) {
        tiles.add(_TemplateTile(
          icon: t.icon,
          label: t.name(en),
          selected: _selectedKey == 'builtin:${t.id}',
          onTap: () => _selectBuiltIn(t),
        ));
      }
    }

    return Wrap(spacing: 10, runSpacing: 10, children: tiles);
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

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 128,
        height: 92,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? nd.accent.withValues(alpha: 0.10) : nd.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? nd.accent : nd.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: selected ? nd.accent : nd.text2),
            const Spacer(),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.2,
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
