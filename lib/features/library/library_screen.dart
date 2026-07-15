import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/nd_colors.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/note_text.dart';
import '../../data/data_providers.dart';
import '../../data/database/database.dart';
import '../shell/actions.dart';
import '../shell/shell_state.dart';
import '../shared/empty_state.dart';

/// Kütüphane: not + PDF kartları ızgarası, filtre çipleri.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nd = context.nd;
    final filter = ref.watch(libraryFilterProvider);
    final docsAsync = ref.watch(documentsProvider);
    final selection = ref.watch(librarySelectionProvider);

    return docsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
          child: Text(context.t('Bir hata oluştu:\n$e', 'Something went wrong:\n$e'))),
      data: (allDocs) {
        final docs = filter == 'tumu'
            ? allDocs
            : allDocs.where((d) => d.type == filter).toList();

        return LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final hpad = w > 1100 ? (w - 1060) / 2 : 20.0;
            final cols = ((w - 2 * hpad + 12) / 244).floor().clamp(1, 6);

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(hpad, 20, hpad, 8),
                  sliver: SliverToBoxAdapter(
                    child: selection.isEmpty
                        ? Row(
                            children: [
                              _Chip(
                                label: context.t('Tümü', 'All'),
                                active: filter == 'tumu',
                                onTap: () => ref
                                    .read(libraryFilterProvider.notifier)
                                    .state = 'tumu',
                              ),
                              const SizedBox(width: 8),
                              _Chip(
                                label: context.t('Notlar', 'Notes'),
                                active: filter == 'not',
                                onTap: () => ref
                                    .read(libraryFilterProvider.notifier)
                                    .state = 'not',
                              ),
                              const SizedBox(width: 8),
                              _Chip(
                                label: context.t("PDF'ler", 'PDFs'),
                                active: filter == 'pdf',
                                onTap: () => ref
                                    .read(libraryFilterProvider.notifier)
                                    .state = 'pdf',
                              ),
                              const Spacer(),
                              Text(
                                context.t('${docs.length} öğe',
                                    '${docs.length} items'),
                                style:
                                    TextStyle(fontSize: 12.5, color: nd.text2),
                              ),
                            ],
                          )
                        : _SelectionBar(selection: selection),
                  ),
                ),
                if (docs.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: filter == 'pdf'
                          ? Icons.picture_as_pdf_outlined
                          : Icons.note_alt_outlined,
                      title: filter == 'pdf'
                          ? context.t('Henüz PDF yok', 'No PDFs yet')
                          : context.t('Henüz belge yok', 'No documents yet'),
                      subtitle: filter == 'pdf'
                          ? context.t(
                              'Sağ üstteki içe aktar düğmesiyle PDF ekleyin.',
                              'Add a PDF with the import button at the top right.')
                          : context.t('Sağ üstteki “Yeni not” ile başlayın.',
                              'Start with “New note” at the top right.'),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(hpad, 8, hpad, 48),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 172,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _DocCard(doc: docs[i]),
                        childCount: docs.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    return Material(
      color: active ? nd.accent : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(color: active ? Colors.transparent : nd.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? nd.accentFg : nd.text2,
            ),
          ),
        ),
      ),
    );
  }
}

class _DocCard extends ConsumerWidget {
  const _DocCard({required this.doc});

  final Document doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nd = context.nd;
    final isPdf = doc.type == 'pdf';
    final selection = ref.watch(librarySelectionProvider);
    final selecting = selection.isNotEmpty;
    final selected = selection.contains(doc.id);
    final title = doc.title.trim().isEmpty
        ? context.t('Adsız not', 'Untitled note')
        : doc.title.trim();
    final preview = plainTextFromBody(doc.body);
    final meta = isPdf
        ? '${doc.pageCount ?? 1} ${context.t('sayfa', 'pages')} · ${formatRelative(doc.updatedAt)}'
        : '${doc.folder} · ${formatRelative(doc.updatedAt)}';

    return Container(
      // "Bombe/kabarık" his: yumuşak üst-ışık gradyanı + yumuşak gölge.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: selected ? nd.accent : nd.border,
            width: selected ? 2 : 1),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(nd.card, Colors.white, 0.06)!,
            Color.lerp(nd.card, Colors.black, 0.05)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 14,
            spreadRadius: -6,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (selecting) {
              final next = {...selection};
              if (!next.remove(doc.id)) next.add(doc.id);
              ref.read(librarySelectionProvider.notifier).state = next;
            } else {
              openDocument(ref, doc);
            }
          },
          onLongPress: () => ref
              .read(librarySelectionProvider.notifier)
              .state = {...selection, doc.id},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        letterSpacing: -0.01,
                      ),
                    ),
                  ),
                  if (doc.sharedId != null) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.people_alt_outlined,
                        size: 15, color: nd.text2),
                  ],
                  if (isPdf) ...[
                    const SizedBox(width: 8),
                    _PdfBadge(nd: nd),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: isPdf
                    ? _PdfThumb(nd: nd)
                    : Text(
                        preview.isEmpty ? context.t('Boş not', 'Empty note') : preview,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: nd.text2,
                        ),
                      ),
              ),
              const SizedBox(height: 10),
              Text(meta, style: TextStyle(fontSize: 12, color: nd.text2)),
            ],
            ),
          ),
        ),
      ),
          if (selecting)
            Positioned(
              top: 10,
              right: 10,
              child: _CheckBadge(selected: selected),
            ),
        ],
      ),
    );
  }
}

class _SelectionBar extends ConsumerWidget {
  const _SelectionBar({required this.selection});

  final Set<int> selection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nd = context.nd;
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.close, size: 20, color: nd.text),
          tooltip: context.t('Vazgeç', 'Cancel'),
          onPressed: () =>
              ref.read(librarySelectionProvider.notifier).state = <int>{},
        ),
        Text(
          '${selection.length} ${context.t('seçili', 'selected')}',
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(Icons.delete_outline, size: 20, color: nd.text),
          tooltip: context.t('Sil', 'Delete'),
          onPressed: () => confirmDeleteDocuments(context, ref, selection),
        ),
      ],
    );
  }
}

class _CheckBadge extends StatelessWidget {
  const _CheckBadge({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: selected ? nd.accent : nd.card,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? nd.accent : nd.borderStrong,
          width: 1.5,
        ),
      ),
      child: selected
          ? Icon(Icons.check, size: 15, color: nd.accentFg)
          : null,
    );
  }
}

class _PdfBadge extends StatelessWidget {
  const _PdfBadge({required this.nd});
  final NdColors nd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: nd.borderStrong),
      ),
      child: Text(
        'PDF',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: nd.text2,
        ),
      ),
    );
  }
}

class _PdfThumb extends StatelessWidget {
  const _PdfThumb({required this.nd});
  final NdColors nd;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: nd.hover,
        borderRadius: BorderRadius.circular(10),
      ),
      child: AspectRatio(
        aspectRatio: 1 / 1.3,
        child: FractionallySizedBox(
          heightFactor: 0.82,
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: nd.borderStrong),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final w in const [0.7, 1.0, 0.92, 1.0, 0.6]) ...[
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: w,
                    child: Container(
                      height: 3,
                      color: const Color(0xFFE9E9E6),
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
