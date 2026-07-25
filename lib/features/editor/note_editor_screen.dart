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
import '../drawing/stroke_painter.dart';
import '../forms/form_layout.dart';
import '../forms/form_model.dart';
import '../forms/form_page.dart';
import '../shell/shell_state.dart';
import 'editor_state.dart';
import 'table_embed.dart';

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
  int _requestedPages = 0;

  /// İçeriğin gerçekte kaç sayfa tuttuğu (`_Sheet` ölçer). Sayfa silme
  /// düğmesi buna bakar: içerik son sayfaya ulaşıyorsa silinemez.
  int _naturalPages = 1;
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

  // Form-not (şablon sayfası): body `{"ndform":1,...}` ise Quill yerine
  // FormPage çizilir; kaydetme/uzak güncelleme de form yolundan gider.
  FormDoc? _form;

  @override
  void initState() {
    super.initState();
    _docId = ref.read(navProvider).activeDocId;
    final doc = ref.read(activeDocumentProvider);
    final body = doc?.body ?? '';
    if (isFormBody(body)) _form = FormDoc.tryParse(body);
    _controller = QuillController(
      document: _form != null ? Document() : _parseDoc(body),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _titleController.text = doc?.title ?? '';
    _loaded = doc != null;
    if (!_loaded) _load();
    _controller.addListener(_scheduleSave);

    // Boş not + yazı modunda açılıyorsa klavye direkt gelsin (yeni not akışı).
    final emptyOnOpen = _loaded && _form == null && body.trim().isEmpty;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_form == null) {
        ref.read(activeQuillControllerProvider.notifier).state = _controller;
      }
      // Araç çubuğundaki tablo düğmesi bu kancayı çağırır.
      ref.read(tableInserterProvider.notifier).state = _insertTable;
      if (emptyOnOpen && ref.read(toolProvider) == PenTool.yazi) {
        _focus.requestFocus();
      }
    });
  }

  /// Araç çubuğundan tablo ekler. Not form değilse (serbest/Quill) önce forma
  /// dönüştürülür: mevcut yazı çizgili bir metin alanına taşınır, tablo onun
  /// altına eklenir. Tablo **sona** eklenir — araya girmek sonraki blokların
  /// index'ini kaydırıp alan biçimlerini bozardı.
  void _insertTable(int rows, int cols) {
    final table = TableBlock.empty(r: rows, c: cols);
    setState(() {
      if (_form == null) {
        final text = _controller.document.toPlainText().trimRight();
        _form = FormDoc([
          if (text.isNotEmpty) AreaBlock(value: text, minLines: 3),
          table,
        ]);
        // Artık Quill çizilmiyor → araç çubuğu form yoluna geçsin.
        if (ref.read(activeQuillControllerProvider) == _controller) {
          ref.read(activeQuillControllerProvider.notifier).state = null;
        }
      } else {
        _form!.blocks.add(table);
      }
    });
    _save();
    // Sayfa sayısı gerekiyorsa `_Sheet`'in bir sonraki çiziminde büyür.
  }

  /// Form içeriği mevcut sayfalara sığmıyorsa sayfa sayısını büyütür (satır/
  /// tablo eklenince yazılan şey kartın altında kırpılıp kaybolmasın). ASLA
  /// küçültmez — kullanıcının elle eklediği boş sayfalar korunur. `_Sheet`
  /// her çiziminde çağırır; aynı isteği iki kez yazmamak için son değer
  /// [_requestedPages]'te tutulur.
  Future<void> _ensurePages(int needed) async {
    final id = _docId;
    final doc = ref.read(activeDocumentProvider);
    if (id == null || doc == null) return;
    if (needed <= (doc.pageCount ?? 1) || needed <= _requestedPages) return;
    _requestedPages = needed;
    await ref
        .read(documentRepositoryProvider)
        .setPageCount(id: id, pageCount: needed);
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
    if (isFormBody(doc.body)) _form = FormDoc.tryParse(doc.body);
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
    if (_form != null) {
      // Form-not: tüm gövde LWW ile değiştirilir (FormPage controller
      // metinlerini didUpdateWidget'ta eşitler).
      _applyingRemote = true;
      try {
        if (u.body != _form!.encode() && isFormBody(u.body)) {
          final next = FormDoc.tryParse(u.body);
          if (next != null) setState(() => _form = next);
        }
        if (_titleController.text != u.title) {
          _titleController.text = u.title;
        }
      } finally {
        _applyingRemote = false;
      }
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
    final body = _form != null
        ? _form!.encode()
        : jsonEncode(_controller.document.toDelta().toJson());
    ref
        .read(documentRepositoryProvider)
        .updateNote(id: id, title: _titleController.text.trim(), body: body);
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

  /// `_Sheet` her çiziminde içeriğin kaç sayfa tuttuğunu bildirir. Büyütme
  /// buradan tetiklenir; "Sayfayı sil" de bu sayıya bakar.
  void _onPagesMeasured(int natural) {
    if (natural != _naturalPages && mounted) {
      setState(() => _naturalPages = natural);
    }
    _ensurePages(natural);
  }

  /// Son sayfaya değen çizimlerin id'leri. Çizim noktaları sayfa genişliğine
  /// göre normalize (0..1) ve tüm sayfalar tek bir düşey düzlemde dizili
  /// olduğu için son sayfanın üst sınırı `(pages-1) * (aspect + boşluk)`.
  Set<int> _strokesOnLastPage(int pages, String? pageSize) {
    final strokes = ref.read(activeStrokesProvider).valueOrNull ?? const [];
    final top = (pages - 1) * (aspectForPageSize(pageSize) + kPageGapRatio);
    final ids = <int>{};
    for (final s in strokes) {
      for (final p in PenStroke.fromRow(s).points) {
        if (p.dy >= top) {
          ids.add(s.id);
          break;
        }
      }
    }
    return ids;
  }

  /// Son sayfayı kaldırır — yalnız o sayfa boşsa. (Sayfa sayısı içerikle
  /// birlikte büyüyor ama kendiliğinden küçülmüyor; içerik silinince arkada
  /// kalan boş kartı kullanıcı böyle temizler.)
  Future<void> _removeLastPage() async {
    final id = _docId;
    final doc = ref.read(activeDocumentProvider);
    if (id == null || doc == null) return;
    final pages = doc.pageCount ?? 1;

    void warn(String tr, String en) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(context.t(tr, en)),
        ));
    }

    if (pages <= 1) {
      warn('Tek sayfa silinemez', 'The only page cannot be deleted');
      return;
    }
    // Yazı/form içeriği son sayfaya taşıyorsa silmek anlamsız — sayfa bir
    // sonraki ölçümde zaten geri gelir. Bunu silmek yerine söylüyoruz.
    if (_naturalPages >= pages) {
      warn('Son sayfada yazı var — önce onu silin',
          'The last page still has text — delete that first');
      return;
    }

    // Çizim varsa engellemek yerine ONAY isteriz (kullanıcı isteği: çizimli
    // sayfa da silinebilmeli). Onaylanırsa o sayfaya değen çizimler silinir.
    final inkIds = _strokesOnLastPage(pages, doc.pageSize);
    if (inkIds.isNotEmpty) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(ctx.t('Sayfa silinsin mi?', 'Delete page?')),
          content: Text(ctx.t(
            'Son sayfada ${inkIds.length} çizim var. Sayfayla birlikte '
                'bunlar da silinecek.',
            'The last page has ${inkIds.length} drawing(s). They will be '
                'deleted along with the page.',
          )),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(ctx.t('Vazgeç', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(ctx.t('Sil', 'Delete')),
            ),
          ],
        ),
      );
      if (ok != true) return;
      await ref.read(drawingRepositoryProvider).deleteStrokes(inkIds);
    }

    // Yeniden büyümeye izin ver (aynı sayıyı tekrar yazabilsin).
    _requestedPages = 0;
    await ref
        .read(documentRepositoryProvider)
        .setPageCount(id: id, pageCount: pages - 1);
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
    // Form notundan çıkarken/başka nota geçerken alan biçim çubuğunu temizle
    // (bayat toggle closure'ı kalmasın).
    if (ref.read(activeFormFieldProvider) != null) {
      ref.read(activeFormFieldProvider.notifier).state = null;
    }
    if (ref.read(tableInserterProvider) == _insertTable) {
      ref.read(tableInserterProvider.notifier).state = null;
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
    final pageBackground = doc?.pageBackground ?? 'duz';

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
                            background: pageBackground,
                            pageSize: pageSize,
                            form: _form,
                            formEditable: textMode,
                            onFormChanged: _scheduleSave,
                            onPagesMeasured: _onPagesMeasured,
                          ),
                          const SizedBox(height: 16),
                          _PageActions(
                            onAdd: _addPage,
                            onRemove: pageCount > 1 ? _removeLastPage : null,
                          ),
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

/// Not sayfaları: her sayfa **bağımsız bir kart** (kendi zemini/kenarı/gölgesi/
/// deseni), aralarında gerçek boşluk. İçerik taşarsa sayfa sayısı otomatik
/// büyür (küsurat sayfa oluşmaz). Form notları sanal A4 genişliğinde dizilip
/// FittedBox'la ölçeklenir → telefonda sığar, çıktıda gerçekçi yoğunluk.
class _Sheet extends ConsumerStatefulWidget {
  const _Sheet({
    required this.docId,
    required this.controller,
    required this.focus,
    required this.editorScroll,
    required this.width,
    required this.pageHeight,
    required this.pageCount,
    required this.paper,
    required this.background,
    required this.pageSize,
    required this.form,
    required this.formEditable,
    required this.onFormChanged,
    required this.onPagesMeasured,
  });

  final int? docId;
  final QuillController controller;
  final FocusNode focus;
  final ScrollController editorScroll;
  final double width;
  final double pageHeight;
  final int pageCount;
  final PaperStyle paper;
  final String background;
  final String pageSize;
  final FormDoc? form;
  final bool formEditable;
  final VoidCallback onFormChanged;

  /// İçeriğin kaç sayfa tuttuğu — her çizimde bildirilir (büyütme + silme).
  final ValueChanged<int> onPagesMeasured;

  @override
  ConsumerState<_Sheet> createState() => _SheetState();
}

class _SheetState extends ConsumerState<_Sheet> {
  final GlobalKey _quillKey = GlobalKey();
  double _quillH = 0;

  /// Form alanlarında bir değişiklik: notu kaydet **ve sayfa kabuğunu yeniden
  /// çiz**. FormPage kendi `setState`'ini yaptığı için buradaki sayfalama
  /// (`layout`) ve sayfa sayısı aksi hâlde eski kalırdı — satır eklenince
  /// içeriğin son kartın altında kaybolmasının sebebi buydu.
  void _formChanged() {
    widget.onFormChanged();
    if (mounted) setState(() {});
  }

  /// Ölçülen sayfa sayısını editöre bildirir (kare bitiminde — build sırasında
  /// üst widget'ın state'ini değiştirmemek için).
  void _reportPages(int n) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onPagesMeasured(n);
    });
  }

  /// Quill içeriğinin çizilen yüksekliğini kare sonrası ölçer (sayfa sayısı
  /// içerikten otomatik büyüsün diye).
  void _scheduleQuillMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box =
          _quillKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      final h = box.size.height;
      if ((h - _quillH).abs() > 0.5) setState(() => _quillH = h);
    });
  }

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    final w = widget.width;
    final pageH = widget.pageHeight;
    final gap = w * kPageGapRatio;
    final paper = widget.paper;

    // Sayfa sayısı: içerik sığmıyorsa otomatik büyür (asla küçülmez).
    // Kontrol her çizimde yapılır — bir zamanlayıcıya bağlı olsaydı, kaçırılan
    // tek bir değişiklikte içerik sayfa kartının altında kırpılırdı.
    var pages = widget.pageCount;
    double contentPad = 22;
    FormLayoutResult? layout;
    double virtualW = 0;

    if (widget.form != null) {
      final m = formMetrics(widget.pageSize);
      virtualW = m.virtualW;
      contentPad = 22 * (w / m.virtualPageW);
      layout = paginateForm(widget.form!, m.virtualW, m.contentH, m.pageSkip,
          editable: widget.formEditable, maxPages: pages);
      _reportPages(formNaturalPageCount(widget.form!, widget.pageSize));
    } else {
      _scheduleQuillMeasure();
      if (_quillH > 0) {
        final needed = ((_quillH + 44 + gap) / (pageH + gap)).ceil();
        _reportPages(needed);
        if (needed > pages) pages = needed;
      }
    }

    final totalH = pages * pageH + (pages - 1) * gap;

    return SizedBox(
      width: w,
      height: totalH,
      child: Stack(
        children: [
          // Bağımsız sayfa kartları (zemin + kenarlık + gölge + desen).
          for (var i = 0; i < pages; i++)
            Positioned(
              top: i * (pageH + gap),
              left: 0,
              right: 0,
              height: pageH,
              child: Container(
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
                  child: CustomPaint(
                    painter:
                        _PageBackgroundPainter(widget.background, paper.line),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          // İçerik (sayfaların üstünden aşağı akar; form sayfalamayla sayfa
          // sınırlarına saygı duyar).
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding:
                  EdgeInsets.fromLTRB(contentPad, contentPad, contentPad, 0),
              child: Theme(
                data: paper.isDark ? AppTheme.dark() : AppTheme.light(),
                child: Builder(
                  builder: (ctx) {
                    if (widget.form != null) {
                      return FittedBox(
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: virtualW,
                          child: FormPage(
                            form: widget.form!,
                            paper: paper,
                            editable: widget.formEditable,
                            onChanged: _formChanged,
                            pageSize: widget.pageSize,
                            layout: layout,
                          ),
                        ),
                      );
                    }
                    return KeyedSubtree(
                      key: _quillKey,
                      child: DefaultTextStyle(
                        style: TextStyle(color: paper.text),
                        child: QuillEditor(
                          focusNode: widget.focus,
                          scrollController: widget.editorScroll,
                          controller: widget.controller,
                          config: QuillEditorConfig(
                            scrollable: false,
                            expands: false,
                            autoFocus: false,
                            padding: EdgeInsets.zero,
                            placeholder: context.t(
                                'Yazmaya başlayın…', 'Start writing…'),
                            customStyles: _noteStyles(ctx, paper.text),
                            embedBuilders: const [TableEmbedBuilder()],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          // Çizim katmanı (yazı modunda dokunuşu editöre bırakır).
          // **Sayfa kartlarına kırpılır:** aksi hâlde katman sayfalar arası
          // boşluğu da kapladığı için oraya da çizilebiliyordu (kâğıdın dışı).
          // ClipPath dokunuşu da kırpar → boşlukta çizim hiç başlamaz, parmak
          // InteractiveViewer'a gider (kaydırma).
          if (widget.docId != null)
            Positioned.fill(
              child: ClipPath(
                clipper: _PagesClipper(pages: pages, pageH: pageH, gap: gap),
                child: DrawingLayer(docId: widget.docId!, page: 0),
              ),
            ),
        ],
      ),
    );
  }
}

/// Çizim katmanını sayfa kartlarıyla sınırlar: sayfalar arası boşluk kâğıdın
/// dışıdır, oraya çizilmemeli.
class _PagesClipper extends CustomClipper<Path> {
  const _PagesClipper({
    required this.pages,
    required this.pageH,
    required this.gap,
  });

  final int pages;
  final double pageH;
  final double gap;

  @override
  Path getClip(Size size) {
    final path = Path();
    for (var i = 0; i < pages; i++) {
      path.addRect(Rect.fromLTWH(0, i * (pageH + gap), size.width, pageH));
    }
    return path;
  }

  @override
  bool shouldReclip(_PagesClipper old) =>
      old.pages != pages || old.pageH != pageH || old.gap != gap;
}

/// Sayfaların altındaki eylemler: sayfa ekle ve (birden fazla sayfa varsa)
/// son sayfayı sil. Silme yalnız son sayfa boşken iş görür — dolu olduğunda
/// sebebini söyler (bkz. `_removeLastPage`).
class _PageActions extends StatelessWidget {
  const _PageActions({required this.onAdd, required this.onRemove});

  final VoidCallback onAdd;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PageActionButton(
          icon: Icons.add,
          label: context.t('Yeni sayfa', 'New page'),
          onTap: onAdd,
        ),
        if (onRemove != null) ...[
          const SizedBox(width: 10),
          _PageActionButton(
            icon: Icons.delete_outline,
            label: context.t('Sayfayı sil', 'Delete page'),
            onTap: onRemove!,
          ),
        ],
      ],
    );
  }
}

class _PageActionButton extends StatelessWidget {
  const _PageActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
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
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: nd.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: nd.text2),
              const SizedBox(width: 7),
              Text(label,
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

/// Sayfa arka planı (kâğıt deseni) — metin ve çizimlerin arkasında.
class _PageBackgroundPainter extends CustomPainter {
  _PageBackgroundPainter(this.type, this.lineColor);

  final String type; // duz | cizgili | kareli | noktali
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    paintPageBackground(canvas, size, type, lineColor);
  }

  @override
  bool shouldRepaint(_PageBackgroundPainter old) =>
      old.type != type || old.lineColor != lineColor;
}

