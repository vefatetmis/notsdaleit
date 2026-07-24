import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/nd_colors.dart';
import '../../core/utils/date_format.dart';
import '../../data/data_providers.dart';
import '../../data/database/database.dart';
import '../shell/actions.dart';
import '../shell/shell_state.dart';

class FoldersScreen extends ConsumerWidget {
  const FoldersScreen({super.key});

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
            const _TagsSection(),
          ],
        ),
      ),
    );
  }
}

/// Klasörler ekranının altındaki gerçek etiketler bölümü. Etikete dokununca
/// kütüphane o etikete göre filtrelenir; uzun basınca yeniden adlandır / sil.
class _TagsSection extends ConsumerWidget {
  const _TagsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nd = context.nd;
    final tags = ref.watch(tagsProvider).valueOrNull ?? const [];
    final counts = ref.watch(tagCountsProvider);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: nd.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: nd.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t('Etiketler', 'Tags'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (tags.isEmpty)
            Text(
              context.t(
                  'Henüz etiket yok. Kütüphanede bir notu seçip "Etiketle" ile '
                      'etiket ekleyin.',
                  'No tags yet. Select a note in the library and use "Etiketle" '
                      'to add one.'),
              style: TextStyle(fontSize: 13, color: nd.text2, height: 1.4),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in tags)
                  _TagChip(tag: t, count: counts[t.id] ?? 0),
              ],
            ),
        ],
      ),
    );
  }
}

class _TagChip extends ConsumerWidget {
  const _TagChip({required this.tag, required this.count});

  final Tag tag;
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nd = context.nd;
    return Material(
      color: nd.bg,
      shape: StadiumBorder(side: BorderSide(color: nd.border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Etikete göre filtrele ve kütüphaneye git ("tümü" tür + bu etiket).
          ref.read(libraryFilterProvider.notifier).state = 'tumu';
          ref.read(libraryTagFilterProvider.notifier).state = tag.id;
          ref.read(navProvider.notifier).go(AppScreen.kutuphane);
        },
        onLongPress: () => _showTagMenu(context, ref, tag),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text.rich(
            TextSpan(
              text: '#${tag.name} ',
              style: TextStyle(fontSize: 13, color: nd.text),
              children: [
                TextSpan(
                  text: '$count',
                  style: TextStyle(fontSize: 12, color: nd.text2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Etikete uzun basınca: yeniden adlandır / sil menüsü.
Future<void> _showTagMenu(BuildContext context, WidgetRef ref, Tag tag) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(context.t('Yeniden adlandır', 'Rename')),
            onTap: () => Navigator.of(context).pop('rename'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(context.t('Etiketi sil', 'Delete tag')),
            onTap: () => Navigator.of(context).pop('delete'),
          ),
        ],
      ),
    ),
  );
  if (action == 'rename') {
    if (context.mounted) await _renameTag(context, ref, tag);
  } else if (action == 'delete') {
    if (context.mounted) await _deleteTag(context, ref, tag);
  }
}

Future<void> _renameTag(BuildContext context, WidgetRef ref, Tag tag) async {
  final controller = TextEditingController(text: tag.name);
  final name = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.t('Etiketi yeniden adlandır', 'Rename tag')),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
            prefixText: '#', hintText: context.t('Etiket adı', 'Tag name')),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.t('Vazgeç', 'Cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: Text(context.t('Kaydet', 'Save')),
        ),
      ],
    ),
  );
  final n = name?.trim() ?? '';
  if (n.isEmpty || n == tag.name) return;
  try {
    await ref.read(tagRepositoryProvider).rename(tag.id, n);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(context.t('"#$n" adında bir etiket zaten var.',
                'A tag named "#$n" already exists.'))),
      );
    }
  }
}

Future<void> _deleteTag(BuildContext context, WidgetRef ref, Tag tag) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.t('"#${tag.name}" silinsin mi?',
          'Delete "#${tag.name}"?')),
      content: Text(context.t(
          'Etiket kaldırılacak; notlar silinmez, yalnızca bu etiketi kaybeder.',
          'The tag is removed; notes are kept, they just lose this tag.')),
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
  await ref.read(tagRepositoryProvider).deleteTag(tag.id);
  // Silinen etiket kütüphanede aktif filtreyse temizle.
  if (ref.read(libraryTagFilterProvider) == tag.id) {
    ref.read(libraryTagFilterProvider.notifier).state = null;
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
        title: Text(context.t('"$name" silinsin mi?', 'Delete "$name"?')),
        content: Text(hasFiles
            ? context.t(
                'Klasör silinecek; içindeki ${files.length} belge "Kişisel" '
                    'klasörüne taşınacak.',
                'The folder will be deleted; the ${files.length} documents '
                    'inside move to "Kişisel".')
            : context.t('Bu klasör silinecek.',
                'This folder will be deleted.')),
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
    if (hasFiles) {
      await ref
          .read(documentRepositoryProvider)
          .reassignFolder(from: name, to: 'Kişisel');
    }
    await ref.read(folderRepositoryProvider).deleteByName(name);
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
                  Text(
                      context.t('${files.length} öğe',
                          '${files.length} item${files.length == 1 ? '' : 's'}'),
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
                        child: Text(context.t('Boş klasör', 'Empty folder'),
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
        onLongPress: () => trashDocument(context, ref, doc),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(36, 9, 10, 9),
          child: Row(
            children: [
              Icon(Icons.description_outlined, size: 16, color: nd.text2),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  doc.title.trim().isEmpty
                      ? context.t('Adsız not', 'Untitled note')
                      : doc.title,
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
              Text(formatRelative(context, doc.updatedAt),
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
          await ref.read(folderRepositoryProvider).add(name.trim());
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
        child: Text(context.t('+ Yeni klasör', '+ New folder'),
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
        title: Text(context.t('Yeni klasör', 'New folder')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
              hintText: context.t('Klasör adı', 'Folder name')),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.t('Vazgeç', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(context.t('Ekle', 'Add')),
          ),
        ],
      ),
    );
  }
}
