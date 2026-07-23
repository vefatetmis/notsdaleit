import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/nd_colors.dart';
import '../../core/utils/date_format.dart';
import '../../data/data_providers.dart';
import '../../data/database/database.dart';
import '../shared/empty_state.dart';
import '../shell/actions.dart';

/// "Son silinenler" — yumuşak silinmiş belgeler. Buradan geri alınır ya da
/// kalıcı silinir. Çöp kutusu boşaltılabilir.
class RecentlyDeletedScreen extends ConsumerWidget {
  const RecentlyDeletedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nd = context.nd;
    final trashedAsync = ref.watch(trashedDocumentsProvider);

    return trashedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
          child: Text(context.t('Bir hata oluştu:\n$e',
              'Something went wrong:\n$e'))),
      data: (docs) {
        if (docs.isEmpty) {
          return EmptyState(
            icon: Icons.delete_outline,
            title: context.t('Çöp kutusu boş', 'Trash is empty'),
            subtitle: context.t(
                'Sildiğin notlar burada görünür; buradan geri alabilir ya da '
                'kalıcı silebilirsin.',
                'Deleted notes appear here; you can restore them or delete '
                'them permanently.'),
          );
        }

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
              children: [
                Row(
                  children: [
                    Text(
                      context.t('${docs.length} öğe', '${docs.length} items'),
                      style: TextStyle(fontSize: 12.5, color: nd.text2),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => emptyTrash(context, ref),
                      icon: const Icon(Icons.delete_forever_outlined, size: 18),
                      label: Text(
                          context.t('Çöp kutusunu boşalt', 'Empty trash')),
                      style: TextButton.styleFrom(foregroundColor: nd.text2),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: nd.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: nd.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < docs.length; i++)
                        _TrashRow(doc: docs[i], showTopBorder: i > 0),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TrashRow extends ConsumerWidget {
  const _TrashRow({required this.doc, required this.showTopBorder});

  final Document doc;
  final bool showTopBorder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nd = context.nd;
    final isPdf = doc.type == 'pdf';
    final title = doc.title.trim().isEmpty
        ? context.t('Adsız not', 'Untitled note')
        : doc.title.trim();
    final when = doc.deletedAt == null
        ? ''
        : context.t('${formatRelative(doc.deletedAt!)} silindi',
            'deleted ${formatRelative(doc.deletedAt!)}');

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: showTopBorder ? BorderSide(color: nd.border) : BorderSide.none,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          children: [
            Icon(
              isPdf ? Icons.picture_as_pdf_outlined : Icons.description_outlined,
              size: 18,
              color: nd.text2,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(when,
                      style: TextStyle(fontSize: 12, color: nd.text2)),
                ],
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.restore, size: 20, color: nd.text),
              tooltip: context.t('Geri al', 'Restore'),
              onPressed: () => restoreDocuments(ref, {doc.id}),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.delete_forever_outlined, size: 20, color: nd.text),
              tooltip: context.t('Kalıcı sil', 'Delete permanently'),
              onPressed: () =>
                  permanentlyDeleteDocuments(context, ref, {doc.id}),
            ),
          ],
        ),
      ),
    );
  }
}
