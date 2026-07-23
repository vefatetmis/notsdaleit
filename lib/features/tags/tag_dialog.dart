import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/nd_colors.dart';
import '../../data/data_providers.dart';

/// Seçili belgelere etiket ekleme/çıkarma diyaloğu. Mevcut etiketler kutucuklu
/// listelenir (seçilinin hepsinde varsa işaretli); dokununca hepsine ekler ya
/// da hepsinden kaldırır. Alttaki alandan yeni etiket oluşturulur.
Future<void> showTagDialog(BuildContext context, WidgetRef ref, Set<int> ids) {
  if (ids.isEmpty) return Future.value();
  return showDialog<void>(context: context, builder: (_) => _TagDialog(ids: ids));
}

class _TagDialog extends ConsumerStatefulWidget {
  const _TagDialog({required this.ids});

  final Set<int> ids;

  @override
  ConsumerState<_TagDialog> createState() => _TagDialogState();
}

class _TagDialogState extends ConsumerState<_TagDialog> {
  final _newCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _newCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggle(int tagId, bool add) async {
    if (_busy) return;
    setState(() => _busy = true);
    await ref.read(tagRepositoryProvider).setLinkForDocs(widget.ids, tagId, add);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _createAndAdd() async {
    final name = _newCtrl.text.trim();
    if (name.isEmpty || _busy) return;
    setState(() => _busy = true);
    final repo = ref.read(tagRepositoryProvider);
    final id = await repo.ensureTag(name);
    if (id > 0) await repo.setLinkForDocs(widget.ids, id, true);
    _newCtrl.clear();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    final tags = ref.watch(tagsProvider).valueOrNull ?? const [];
    final docTags = ref.watch(docTagIdsProvider);

    return Dialog(
      backgroundColor: nd.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: nd.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360, maxHeight: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.t('Etiketle', 'Tag'),
                  style: const TextStyle(
                      fontSize: 15.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(
                  context.t('${widget.ids.length} öğe seçildi',
                      '${widget.ids.length} selected'),
                  style: TextStyle(fontSize: 12.5, color: nd.text2)),
              const SizedBox(height: 6),
              if (tags.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    context.t('Henüz etiket yok. Aşağıdan oluşturun.',
                        'No tags yet. Create one below.'),
                    style: TextStyle(fontSize: 13.5, color: nd.text2),
                  ),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final t in tags)
                        _TagRow(
                          name: t.name,
                          checked: widget.ids
                              .every((id) => docTags[id]?.contains(t.id) ?? false),
                          onTap: _busy
                              ? null
                              : () {
                                  final all = widget.ids.every((id) =>
                                      docTags[id]?.contains(t.id) ?? false);
                                  _toggle(t.id, !all);
                                },
                        ),
                    ],
                  ),
                ),
              const Divider(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newCtrl,
                      onSubmitted: (_) => _createAndAdd(),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        prefixText: '#',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        hintText: context.t('Yeni etiket', 'New tag'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.add, color: nd.text),
                    onPressed: _busy ? null : _createAndAdd,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({required this.name, required this.checked, required this.onTap});

  final String name;
  final bool checked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
        child: Row(
          children: [
            Icon(
              checked ? Icons.check_box : Icons.check_box_outline_blank,
              size: 21,
              color: checked ? nd.accent : nd.text2,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('#$name',
                  style: TextStyle(fontSize: 14, color: nd.text)),
            ),
          ],
        ),
      ),
    );
  }
}
