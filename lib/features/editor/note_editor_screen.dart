import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/nd_colors.dart';
import '../../data/data_providers.dart';
import '../collab/collab_service.dart';
import '../drawing/drawing_layer.dart';
import '../drawing/drawing_state.dart';
import '../shell/shell_state.dart';
import 'editor_state.dart';

/// Birleşik not editörü: boyutlu sayfa üzerinde hem **biçimli yazı**
/// (flutter_quill) hem **kalemle çizim**. Araç çubuğundaki **Aa** ile yazı
/// moduna, kalem araçlarıyla çizim moduna geçilir.
///
/// Kaydırma/yakınlaştırma tek bir [InteractiveViewer] ile yapılır:
/// - iki parmakla **dokunduğun noktaya doğru** yakınlaştırır (odak noktalı),
/// - yazı/el modunda **tek parmak** kaydırır,
/// - kalem modunda **tek parmak çizer**, **iki parmak** kaydırır/yakınlaştırır.
class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final QuillController _controller;
  final _focus = FocusNode();
  final _editorScroll = ScrollController();
  final _titleController = TextEditingController();
  final _tc = TransformationController();
  Timer? _saveTimer;
  int? _docId;
  bool _loaded = false;
  bool _addingPage = false;

  // Ekrandaki aktif parmak sayısı (kalem modunda iki parmakla kaydırmayı
  // ayırt etmek için: 1 parmak çizer, 2 parmak InteractiveViewer'a bırakılır).
  int _pointers = 0;

  // Canlı ortak not: uzaktan gelen metni uygularken yerel kaydetme/yankı
  // döngüsünü kes; kullanıcı az önce yazdıysa uzaktan geleni uygulama (onun
  // sürümü zaten sunucuya gidecek).
  bool _applyingRemote = false;
  DateTime _lastLocalEdit = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _docId = ref.read(navProvider).activeDocId;
    final doc = ref.read(activeDocumentProvider);
    _controller = QuillController(
      document: _parseDoc(doc?.body ?? ''),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _titleController.text = doc?.title ?? '';
    _loaded = doc != null;
    if (!_loaded) _load();
    _controller.addListener(_scheduleSave);

    // Boş not + yazı modunda açılıyorsa klavye direkt gelsin (yeni not akışı).
    final emptyOnOpen = _loaded && (doc?.body ?? '').trim().isEmpty;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(activeQuillControllerProvider.notifier).state = _controller;
      if (emptyOnOpen && ref.read(toolProvider) == PenTool.yazi) {
        _focus.requestFocus();
      }
    });
  }

  Document _parseDoc(String body) {
    if (body.trim().isEmpty) return Document();
    try {
      final data = jsonDecode(body);
      if (data is List) return Document.fromJson(data);
    } catch (_) {
      // Eski düz metin notu → tek paragraf.
    }
    return Document.fromJson([
      {'insert': body.endsWith('\n') ? body : '$body\n'}
    ]);
  }

  Future<void> _load() async {
    final id = _docId;
    if (id == null) return;
    final doc = await ref.read(documentRepositoryProvider).getById(id);
    if (!mounted || doc == null) return;
    _titleController.text = doc.title;
    setState(() => _loaded = true);
  }

  void _scheduleSave() {
    if (_applyingRemote) return;
    _lastLocalEdit = DateTime.now();
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), _save);
  }

  /// Uzaktan gelen not içeriğini açık editöre uygular (canlı ortak not).
  void _applyRemoteUpdate(RemoteNoteUpdate u) {
    if (u.docId != _docId || !mounted) return;
    // Kullanıcı şu an yazıyorsa dokunma; onun sürümü sunucuya gidecek (LWW).
    if (DateTime.now().difference(_lastLocalEdit) <
        const Duration(seconds: 3)) {
      return;
    }
    _applyingRemote = true;
    try {
      final current =
          jsonEncode(_controller.document.toDelta().toJson());
      if (current != u.body) {
        final sel = _controller.selection;
        final doc = _parseDoc(u.body);
        _controller.document = doc;
        final off = sel.baseOffset.clamp(0, doc.length - 1);
        _controller.updateSelection(
            TextSelection.collapsed(offset: off), ChangeSource.local);
      }
      if (_titleController.text != u.title) {
        _titleController.text = u.title;
      }
    } catch (_) {
      // Uygulanamadıysa (beklenmedik biçim) yerel kopya drift'te güncel kaldı.
    } finally {
      _applyingRemote = false;
    }
  }

  void _save() {
    final id = _docId;
    if (id == null || !_loaded) return;
    final json = jsonEncode(_controller.document.toDelta().toJson());
    ref
        .read(documentRepositoryProvider)
        .updateNote(id: id, title: _titleController.text.trim(), body: json);
  }

  Future<void> _addPage() async {
    if (_addingPage) return;
    final id = _docId;
    final doc = ref.read(activeDocumentProvider);
    if (id == null || doc == null) return;
    _addingPage = true;
    final next = (doc.pageCount ?? 1) + 1;
    await ref
        .read(documentRepositoryProvider)
        .setPageCount(id: id, pageCount: next);
    _addingPage = false;
  }

  void _onPointerChange(int delta) {
    final next = (_pointers + delta).clamp(0, 10);
    if (next != _pointers) setState(() => _pointers = next);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _save();
    if (ref.read(activeQuillControllerProvider) == _controller) {
      ref.read(activeQuillControllerProvider.notifier).state = null;
    }
    _controller.dispose();
    _focus.dispose();
    _editorScroll.dispose();
    _titleController.dispose();
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Not paylaşımlıysa canlı oturumu açık tut ve uzaktan gelen metni dinle.
    ref.watch(collabSessionProvider);
    ref.listen(remoteNoteUpdateProvider, (_, next) {
      if (next != null) _applyRemoteUpdate(next);
    });
    // Paylaşım sona erdiyse (sahibi durdurdu) tek seferlik bilgilendir.
    ref.listen(collabEndedProvider, (prev, next) {
      if (prev != null && next != prev && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.t(
                'Canlı paylaşım sonlandırıldı', 'Live sharing ended'))));
      }
    });

    final doc = ref.watch(activeDocumentProvider);
    final tool = ref.watch(toolProvider);
    final textMode = tool == PenTool.yazi;
    final penActive = tool.isPen;

    _controller.readOnly = !textMode;

    final pageSize = doc?.pageSize ?? 'a4';
    final aspect = aspectForPageSize(pageSize);
    final pageCount = doc?.pageCount ?? 1;
    final paper = paperStyleFor(doc?.pageColor);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
          child: TextField(
            controller: _titleController,
            onChanged: (_) => _scheduleSave(),
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: context.t('Başlık', 'Title'),
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final baseW = (c.maxWidth - 32).clamp(120.0, 680.0);
              final pageHBase = baseW * aspect;

              return Listener(
                onPointerDown: (_) => _onPointerChange(1),
                onPointerUp: (_) => _onPointerChange(-1),
                onPointerCancel: (_) => _onPointerChange(-1),
                child: InteractiveViewer(
                  transformationController: _tc,
                  constrained: false,
                  // Varsayılan zoom = tam genişlik; yalnızca yakınlaştırınca
                  // yatay kaydırma açılır (sayfa genişliği görünüme eşit olduğu
                  // için 1.0'da sağa-sola oynamaz → "oynak" hissi biter).
                  minScale: 1.0,
                  maxScale: 4.0,
                  // Kalem modunda tek parmak çizer (pan kapalı); ikinci parmak
                  // gelince pan açılır → iki parmakla kaydır/yakınlaştır. Yazı/el
                  // modunda tek parmak kaydırır.
                  panEnabled: penActive ? _pointers >= 2 : true,
                  scaleEnabled: true,
                  // Sıfır kenar boşluğu: içerik kenarları görünüm kenarını
                  // geçemez → 1.0'da yatay kilit, dikey tam kaydırma.
                  boundaryMargin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: SizedBox(
                      width: baseW,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _Sheet(
                            docId: _docId,
                            controller: _controller,
                            focus: _focus,
                            editorScroll: _editorScroll,
                            width: baseW,
                            pageHeight: pageHBase,
                            pageCount: pageCount,
                            paper: paper,
                          ),
                          const SizedBox(height: 16),
                          _AddPageButton(onTap: _addPage),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Not editöründe metin renklerini kağıda göre (temadan bağımsız) zorlayan
/// stiller. Böylece açık/koyu tema değişse de yazı okunur; siyah kağıtta beyaz.
DefaultStyles _noteStyles(BuildContext ctx, Color textColor) {
  // Kısmi stil döndürürüz; QuillEditor bunu kendi varsayılanlarıyla birleştirir.
  final b = DefaultStyles.getInstance(ctx);
  final p = b.paragraph!;
  final ph = b.placeHolder!;
  return DefaultStyles(
    paragraph: DefaultTextBlockStyle(
      p.style.copyWith(color: textColor, fontSize: kBaseFontSize),
      p.horizontalSpacing,
      p.verticalSpacing,
      p.lineSpacing,
      p.decoration,
    ),
    placeHolder: DefaultTextBlockStyle(
      ph.style.copyWith(color: textColor.withValues(alpha: 0.4)),
      ph.horizontalSpacing,
      ph.verticalSpacing,
      ph.lineSpacing,
      ph.decoration,
    ),
  );
}

class _Sheet extends ConsumerWidget {
  const _Sheet({
    required this.docId,
    required this.controller,
    required this.focus,
    required this.editorScroll,
    required this.width,
    required this.pageHeight,
    required this.pageCount,
    required this.paper,
  });

  final int? docId;
  final QuillController controller;
  final FocusNode focus;
  final ScrollController editorScroll;
  final double width;
  final double pageHeight;
  final int pageCount;
  final PaperStyle paper;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nd = context.nd;
    final minHeight = pageHeight * pageCount;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: paper.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: nd.borderStrong),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          children: [
            // Sayfa ayırıcıları (metnin arkasında) — sayfalar arası boşluk hissi.
            Positioned.fill(
              child: CustomPaint(
                painter: _PageLinesPainter(pageHeight, paper.isDark),
              ),
            ),
            // Minimum yükseklik (sayfa sayısına göre).
            SizedBox(width: width, height: minHeight),
            // Zengin metin — renkler kağıda göre zorlanır (temadan bağımsız).
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
              child: Theme(
                data: paper.isDark ? AppTheme.dark() : AppTheme.light(),
                child: Builder(
                  builder: (ctx) {
                    return DefaultTextStyle(
                      style: TextStyle(color: paper.text),
                      child: QuillEditor(
                        focusNode: focus,
                        scrollController: editorScroll,
                        controller: controller,
                        config: QuillEditorConfig(
                          scrollable: false,
                          expands: false,
                          autoFocus: false,
                          padding: EdgeInsets.zero,
                          placeholder:
                              context.t('Yazmaya başlayın…', 'Start writing…'),
                          customStyles: _noteStyles(ctx, paper.text),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Çizim katmanı (yazı modunda dokunuşu editöre bırakır).
            if (docId != null)
              Positioned.fill(
                child: DrawingLayer(docId: docId!, page: 0),
              ),
          ],
        ),
      ),
    );
  }
}

/// Sayfa altındaki "yeni sayfa ekle" düğmesi.
class _AddPageButton extends StatelessWidget {
  const _AddPageButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    return Material(
      color: nd.card,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: nd.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 18, color: nd.text2),
              const SizedBox(width: 7),
              Text(context.t('Yeni sayfa', 'New page'),
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: nd.text2)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageLinesPainter extends CustomPainter {
  _PageLinesPainter(this.pageHeight, this.darkPaper);

  final double pageHeight;
  final bool darkPaper;

  @override
  void paint(Canvas canvas, Size size) {
    if (pageHeight <= 0) return;
    // Sayfa sınırında ince bir çizgi + hafif gölge bandı → sayfalar arası
    // "boşluk" hissi (tek sürekli sayfada görsel ayrım).
    final line = Paint()
      ..color = darkPaper ? const Color(0x33FFFFFF) : const Color(0x1A000000)
      ..strokeWidth = 1;
    for (var y = pageHeight; y < size.height - 1; y += pageHeight) {
      final band = Rect.fromLTWH(0, y - 7, size.width, 14);
      canvas.drawRect(
        band,
        Paint()
          ..color = darkPaper
              ? const Color(0x22000000)
              : const Color(0x0A000000),
      );
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(_PageLinesPainter old) =>
      old.pageHeight != pageHeight || old.darkPaper != darkPaper;
}
