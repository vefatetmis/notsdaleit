import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/nd_colors.dart';
import '../../core/utils/date_format.dart';
import '../../data/data_providers.dart';
import '../../data/database/database.dart';
import '../shell/actions.dart';
import '../shell/shell_state.dart';

class FoldersScreen extends ConsumerWidget {
  const FoldersScreen({super.key});

  static const _tags = [
    ('önemli', 4),
    ('sınav', 2),
    ('fikir', 3),
    ('taslak', 1),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nd = context.nd;
    final folders = ref.watch(folderNamesProvider);
    final docs = ref.watch(documentsProvider).valueOrNull ?? const [];
    final open = ref.watch(openFoldersProvider);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
          children: [
            Container(
              decoration: BoxDecoration(
                color: nd.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: nd.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < folders.length; i++)
                    _FolderTile(
                      name: folders[i],
                      files: docs.where((d) => d.folder == folders[i]).toList(),
                      isOpen: open.contains(folders[i]),
                      showTopBorder: i > 0,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _NewFolderButton(),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: nd.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: nd.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Etiketler',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in _tags)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: nd.bg,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: nd.border),
                          ),
                          child: Text.rich(
                            TextSpan(
                              text: '#${t.$1} ',
                              style: const TextStyle(fontSize: 13),
                              children: [
                                TextSpan(
                                  text: '${t.$2}',
                                  style: TextStyle(
                                      fontSize: 12, color: nd.text2),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderTile extends ConsumerWidget {
  const _FolderTile({
    required this.name,
    required this.files,
    required this.isOpen,
    required this.showTopBorder,
  });

  final String name;
  final List<Document> files;
  final bool isOpen;
  final bool showTopBorder;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final hasFiles = files.isNotEmpty;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('"$name" silinsin mi?'),
        content: Text(hasFiles
            ? 'Klasör silinecek; içindeki ${files.length} belge "Kişisel" '
                'klasörüne taşınacak.'
            : 'Bu klasör silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (hasFiles) {
      await ref
          .read(documentRepositoryProvider)
          .reassignFolder(from: name, to: 'Kişisel');
    }
    ref.read(extraFoldersProvider.notifier).remove(name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nd = context.nd;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: showTopBorder
              ? BorderSide(color: nd.border)
              : BorderSide.none,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => ref.read(openFoldersProvider.notifier).toggle(name),
            onLongPress: name == 'Kişisel'
                ? null
                : () => _confirmDelete(context, ref),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(Icons.keyboard_arrow_down,
                        size: 20, color: nd.text2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text('${files.length} öğe',
                      style: TextStyle(fontSize: 12.5, color: nd.text2)),
                ],
              ),
            ),
          ),
          if (isOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
              child: Column(
                children: [
                  if (files.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(36, 6, 10, 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Boş klasör',
                            style: TextStyle(fontSize: 13.5, color: nd.text2)),
                      ),
                    )
                  else
                    for (final f in files) _FileRow(doc: f),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FileRow extends ConsumerWidget {
  const _FileRow({required this.doc});
  final Document doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nd = context.nd;
    final isPdf = doc.type == 'pdf';
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openDocument(ref, doc),
        onLongPress: () => confirmDeleteDocument(context, ref, doc),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(36, 9, 10, 9),
          child: Row(
            children: [
              Icon(Icons.description_outlined, size: 16, color: nd.text2),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  doc.title.trim().isEmpty ? 'Adsız not' : doc.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w500),
                ),
              ),
              if (isPdf) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: nd.borderStrong),
                  ),
                  child: Text('PDF',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: nd.text2)),
                ),
                const SizedBox(width: 8),
              ],
              Text(formatRelative(doc.updatedAt),
                  style: TextStyle(fontSize: 12, color: nd.text2)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewFolderButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nd = context.nd;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final name = await _promptName(context);
        if (name != null && name.trim().isNotEmpty) {
          ref.read(extraFoldersProvider.notifier).add(name.trim());
          ref.read(openFoldersProvider.notifier).open(name.trim());
        }
      },
      child: Container(
        padding: const EdgeInsets.all(13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: nd.borderStrong),
        ),
        child: Text('+ Yeni klasör',
            style: TextStyle(
                fontSize: 13.5, fontWeight: FontWeight.w600, color: nd.text2)),
      ),
    );
  }

  Future<String?> _promptName(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni klasör'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Klasör adı'),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }
}
