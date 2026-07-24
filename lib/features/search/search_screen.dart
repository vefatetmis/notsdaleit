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

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(searchQueryProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    final query = ref.watch(searchQueryProvider);
    final q = query.trim().toLowerCase();
    final allDocs = ref.watch(documentsProvider).valueOrNull ?? const [];

    final results = q.isEmpty
        ? allDocs
        : allDocs
            .where((d) => ('${d.title} ${d.folder} ${plainTextFromBody(d.body)}')
                .toLowerCase()
                .contains(q))
            .toList();

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
          children: [
            // Arama kutusu
            Container(
              decoration: BoxDecoration(
                color: nd.card,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: nd.border),
              ),
              padding: const EdgeInsets.only(left: 18, right: 8),
              child: Row(
                children: [
                  Icon(Icons.search, size: 18, color: nd.text2),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: (v) =>
                          ref.read(searchQueryProvider.notifier).state = v,
                      style: const TextStyle(fontSize: 14.5),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: context.t('Not, PDF veya klasör ara',
                            'Search notes, PDFs or folders'),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (q.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      color: nd.text2,
                      onPressed: () {
                        _controller.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (q.isNotEmpty && results.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: nd.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: nd.border),
                ),
                child: Text(
                  context.t('"$query" için sonuç bulunamadı',
                      'No results for "$query"'),
                  style: TextStyle(fontSize: 14, color: nd.text2),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: nd.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: nd.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < results.length; i++)
                      _ResultRow(doc: results[i], showTopBorder: i > 0),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends ConsumerWidget {
  const _ResultRow({required this.doc, required this.showTopBorder});
  final Document doc;
  final bool showTopBorder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nd = context.nd;
    final isPdf = doc.type == 'pdf';
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: showTopBorder ? BorderSide(color: nd.border) : BorderSide.none,
        ),
      ),
      child: InkWell(
        onTap: () => openDocument(ref, doc),
        onLongPress: () => trashDocument(context, ref, doc),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Icon(Icons.description_outlined, size: 16, color: nd.text2),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.title.trim().isEmpty
                          ? context.t('Adsız not', 'Untitled note')
                          : doc.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${doc.folder} · ${formatRelative(context, doc.updatedAt)}',
                      style: TextStyle(fontSize: 12, color: nd.text2),
                    ),
                  ],
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
              Icon(Icons.chevron_right, size: 18, color: nd.text2),
            ],
          ),
        ),
      ),
    );
  }
}
