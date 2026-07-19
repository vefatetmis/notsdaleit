import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/nd_colors.dart';
import '../../data/data_providers.dart';
import '../shell/shell_state.dart';

/// Seçili belgeleri bir klasöre taşıma diyaloğu (mevcut klasör seç ya da yeni
/// klasör oluştur). Taşıyınca kütüphane seçimini temizler.
Future<void> showMoveToFolderDialog(
    BuildContext context, WidgetRef ref, Set<int> ids) {
  if (ids.isEmpty) return Future.value();
  return showDialog<void>(context: context, builder: (_) => _MoveDialog(ids: ids));
}

class _MoveDialog extends ConsumerStatefulWidget {
  const _MoveDialog({required this.ids});

  final Set<int> ids;

  @override
  ConsumerState<_MoveDialog> createState() => _MoveDialogState();
}

class _MoveDialogState extends ConsumerState<_MoveDialog> {
  final _newCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _newCtrl.dispose();
    super.dispose();
  }

  Future<void> _apply(String folder) async {
    if (_busy) return;
    setState(() => _busy = true);
    final repo = ref.read(documentRepositoryProvider);
    for (final id in widget.ids) {
      await repo.updateFolder(id: id, folder: folder);
    }
    ref.read(librarySelectionProvider.notifier).state = <int>{};
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _createAndApply() async {
    final name = _newCtrl.text.trim();
    if (name.isEmpty || _busy) return;
    await ref.read(folderRepositoryProvider).add(name);
    await _apply(name);
  }

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    final folders = ref.watch(folderNamesProvider);

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
              Text(context.t('Klasöre taşı', 'Move to folder'),
                  style: const TextStyle(
                      fontSize: 15.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(
                  context.t('${widget.ids.length} öğe seçildi',
                      '${widget.ids.length} selected'),
                  style: TextStyle(fontSize: 12.5, color: nd.text2)),
              const SizedBox(height: 10),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final f in folders)
                      ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        leading: Icon(Icons.folder_outlined,
                            size: 20, color: nd.text2),
                        title: Text(f,
                            style: TextStyle(fontSize: 14, color: nd.text)),
                        onTap: _busy ? null : () => _apply(f),
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
                      onSubmitted: (_) => _createAndApply(),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        hintText: context.t('Yeni klasör', 'New folder'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.add, color: nd.text),
                    onPressed: _busy ? null : _createAndApply,
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
