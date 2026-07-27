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
import '../forms/form_layout.dart';
import '../forms/form_model.dart';
import '../forms/form_page.dart';
import '../forms/insert_image.dart';
import '../shell/shell_state.dart';
import 'editor_state.dart';
import 'image_layer.dart';
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
  bool _loaded = false;
  String? _imagesDirPath;

  // Görünen sayfayı hesaplamak için son çizim ölçüleri (build'de güncellenir,
  // `_onTransform` okur).
  double _pageH = 0;
  double _gap = 0;
  double _viewportH = 0;
  int _pages = 1;

  // ── Yakınlaştırma / kaydırma jesti ────────────────────────────────────
  //
  // `InteractiveViewer`'ın **jesti** kullanılamadı (widget'ın kendisi duruyor;
  // yalnızca dönüşümü uygular ve `constrained: false` ile ölçüyü yönetir).
  // Sebebi Flutter kaynağında: `_getGestureType` jest türünü **ilk
  // güncellemede** seçip jest boyunca kilitler; iki parmak ekrana aynı anda
  // değdiğinde o ilk karede `details.scale` tam 1.0 olduğu için tür "pan"
  // çıkar ve ardından `case _GestureType.pan` içindeki
  // `if (details.scale != 1.0) { …; return; }` ile **tüm ölçek değişimleri
  // atılır**. Sahada "yakınlaştırdım, geri küçültemiyorum" bunun sonucuydu
  // (üç turda çözülemedi). Matrisi kendimiz sürünce jest türü diye bir şey
  // kalmıyor.
  static const double _kMinZoom = 1.0;
  static const double _kMaxZoom = 4.0;

  final Map<int, Offset> _touch = {};
  double? _pinchDist0;
  double _pinchScale0 = 1;
  Offset _pinchFocalScene = Offset.zero;
  Offset? _panLast;
  bool _penMode = false; // build'de güncellenir
  double _viewportW = 0;
  double _contentW = 0;
  double _contentH = 0;

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
    _tc.addListener(_onTransform);
    // Görsellerin klasörü (asenkron) — FormPage'e yol olarak geçilir.
    imagesDir().then((d) {
      if (mounted) setState(() => _imagesDirPath = d.path);
    });

    // Boş not + yazı modunda açılıyorsa klavye direkt gelsin (yeni not akışı).
    final emptyOnOpen = _loaded && _form == null && body.trim().isEmpty;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Not baştan açılır → görünen sayfa 1.
      ref.read(currentPageProvider.notifier).state = 0;
      if (_form == null) {
        ref.read(activeQuillControllerProvider.notifier).state = _controller;
      }
      // Araç çubuğundaki tablo düğmesi bu kancayı çağırır.
      ref.read(tableInserterProvider.notifier).state = _insertTable;
      // Belge menüsündeki "Görsel ekle" bu kancayı çağırır.
      ref.read(imageInserterProvider.notifier).state = _insertImage;
      // Belge menüsündeki "Yakınlaştırmayı sıfırla".
      ref.read(zoomResetterProvider.notifier).state = _resetZoom;
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

  /// Belge menüsünden görsel ekler. **Notu forma dönüştürmez** — görsel,
  /// çizimler gibi sayfanın üzerine serbestçe yerleştirilen ayrı bir katmandır
  /// (`NoteImages` tablosu). Bakılan sayfanın üst-ortasına konur; kullanıcı
  /// sürükleyip boyutlandırır.
  Future<void> _insertImage(String name, double aspect) async {
    final id = _docId;
    final doc = ref.read(activeDocumentProvider);
    if (id == null || doc == null) return;
    final step = aspectForPageSize(doc.pageSize) + kPageGapRatio;
    final page = ref.read(currentPageProvider);
    const w = 0.5;
    final imgId = await ref.read(noteImageRepositoryProvider).add(
          docId: id,
          file: name,
          x: (1 - w) / 2,
          y: page * step + 0.08,
          w: w,
          aspect: aspect,
        );
    // Yeni görsel seçili gelsin ki tutamakları görünsün.
    if (mounted) ref.read(selectedImageProvider.notifier).state = imgId;
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

  /// `_Sheet` her çiziminde içeriğin kaç sayfa tuttuğunu bildirir → gerekiyorsa
  /// sayfa sayısı büyür.
  void _onPagesMeasured(int natural) => _ensurePages(natural);

  /// Viewport noktasını içerik (sahne) uzayına çevirir.
  Offset _toScene(Offset p) =>
      MatrixUtils.transformPoint(Matrix4.inverted(_tc.value), p);

  /// Matrisi sınırlara oturtur: içerik görünümden büyükse kenarları geçmesin,
  /// küçükse ortalansın (yatay) / başa yaslansın (dikey).
  Matrix4 _clampMatrix(double scale, double tx, double ty) {
    final cw = _contentW * scale;
    final ch = _contentH * scale;
    final nx = cw <= _viewportW
        ? (_viewportW - cw) / 2
        : tx.clamp(_viewportW - cw, 0.0);
    final ny = ch <= _viewportH ? 0.0 : ty.clamp(_viewportH - ch, 0.0);
    return Matrix4.identity()
      ..translate(nx, ny)
      ..scale(scale);
  }

  void _onTouchDown(PointerDownEvent e) {
    _touch[e.pointer] = e.localPosition;
    _pinchDist0 = null; // iki parmağa geçişte referans yeniden alınır
    _panLast = _touch.length == 1 ? e.localPosition : null;
  }

  void _onTouchMove(PointerMoveEvent e) {
    if (!_touch.containsKey(e.pointer)) return;
    _touch[e.pointer] = e.localPosition;

    if (_touch.length >= 2) {
      _panLast = null;
      _applyPinch();
      return;
    }
    // Tek parmak: kalem modunda çizim DrawingLayer'ın — sayfa kaymaz.
    if (_penMode) return;
    final last = _panLast;
    _panLast = e.localPosition;
    if (last == null) return;
    final d = e.localPosition - last;
    final m = _tc.value;
    final t = m.getTranslation();
    _tc.value = _clampMatrix(m.getMaxScaleOnAxis(), t.x + d.dx, t.y + d.dy);
  }

  void _onTouchUp(PointerEvent e) {
    _touch.remove(e.pointer);
    _pinchDist0 = null;
    _panLast = _touch.length == 1 ? _touch.values.first : null;
    if (_touch.isEmpty) {
      // 1'e çok yakınsa tam otursun (kıl payı büyük kalmasın).
      final sc = _tc.value.getMaxScaleOnAxis();
      if (sc > 1.0 && sc < 1.03) _resetZoom();
    }
  }

  void _applyPinch() {
    final pts = _touch.values.toList();
    final a = pts[0];
    final b = pts[1];
    final dist = (a - b).distance;
    final focal = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);

    // İlk kare: yalnız referansları al (ölçek değişimi yok).
    if (_pinchDist0 == null || dist <= 0) {
      _pinchDist0 = dist <= 0 ? null : dist;
      _pinchScale0 = _tc.value.getMaxScaleOnAxis();
      _pinchFocalScene = _toScene(focal);
      return;
    }

    final target =
        (_pinchScale0 * dist / _pinchDist0!).clamp(_kMinZoom, _kMaxZoom);
    // Parmakların ortasındaki sahne noktası yerinde kalsın:
    //   ekran = sahne × ölçek + t   →   t = focal − sahne × ölçek
    _tc.value = _clampMatrix(
      target,
      focal.dx - _pinchFocalScene.dx * target,
      focal.dy - _pinchFocalScene.dy * target,
    );
  }

  /// Yakınlaştırmayı başa döndürür (üst bar menüsü + pinch sonrası oturtma).
  void _resetZoom() {
    _tc.value = Matrix4.identity();
    _onTransform();
  }

  /// Görünümün ortası hangi sayfa kartına denk geliyor? Üst bardaki "sayfa
  /// ekle / sayfayı sil" bunu kullanır (kullanıcıya hangi sayfa olduğu
  /// sorulmaz — baktığı sayfa neyse odur).
  void _onTransform() {
    if (!mounted || _pageH <= 0) return;
    final m = _tc.value;
    final scale = m.getMaxScaleOnAxis();
    if (scale <= 0) return;
    final top = -m.getTranslation().y / scale;
    final center = top + _viewportH / (2 * scale);
    final step = _pageH + _gap;
    if (step <= 0) return;
    final page = ((center - 12) / step).floor().clamp(0, _pages - 1);
    if (page != ref.read(currentPageProvider)) {
      ref.read(currentPageProvider.notifier).state = page;
    }
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
    if (ref.read(imageInserterProvider) == _insertImage) {
      ref.read(imageInserterProvider.notifier).state = null;
    }
    if (ref.read(zoomResetterProvider) == _resetZoom) {
      ref.read(zoomResetterProvider.notifier).state = null;
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
              // `_onTransform` + jest sınırlaması bu ölçüleri kullanır.
              _pageH = pageHBase;
              _gap = baseW * kPageGapRatio;
              _viewportH = c.maxHeight;
              _viewportW = c.maxWidth;
              _pages = pageCount;
              _penMode = penActive;
              // İçerik kutusu: yanlarda 16+16, üstte 12 padding + sayfalar +
              // alttaki 70'lik boşluk.
              _contentW = baseW + 32;
              _contentH = 12 +
                  (pageCount * pageHBase + (pageCount - 1) * _gap) +
                  70;

              // Jestler BİZDE (bkz. alan tanımlarındaki not): InteractiveViewer
              // yalnızca dönüşümü uygular ve `constrained: false` ile içeriğin
              // kendi boyutunu almasını sağlar.
              return Listener(
                // translucent: sayfa aralıkları/boşluklar gibi çocuğun
                // hit-test'e cevap vermediği yerlerde de jesti alalım, ama
                // çocuklar (Quill, çizim, görsel) dokunuşu almaya devam etsin.
                behavior: HitTestBehavior.translucent,
                onPointerDown: _onTouchDown,
                onPointerMove: _onTouchMove,
                onPointerUp: _onTouchUp,
                onPointerCancel: _onTouchUp,
                child: InteractiveViewer(
                  transformationController: _tc,
                  constrained: false,
                  minScale: _kMinZoom,
                  maxScale: _kMaxZoom,
                  panEnabled: false,
                  scaleEnabled: false,
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
                            imagesDirPath: _imagesDirPath,
                            onFormChanged: _scheduleSave,
                            onPagesMeasured: _onPagesMeasured,
                          ),
                          // Sayfa ekle/sil artık üst bar menüsünde (sayfa
                          // altındaki şerit kaldırıldı — sıkışıklık yapıyordu).
                          const SizedBox(height: 70),
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
    required this.imagesDirPath,
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
  final String? imagesDirPath;
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
                            imagesDirPath: widget.imagesDirPath,
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
                child: Stack(
                  children: [
                    // Görseller çizimlerin ALTINDA: kalemle görselin üzerine
                    // yazılabilsin/çizilebilsin.
                    ImageLayer(
                      docId: widget.docId!,
                      width: w,
                      imagesDirPath: widget.imagesDirPath,
                      // Kalem modunda dokunuşlar çizime gitmeli.
                      interactive: !ref.watch(toolProvider).isPen,
                    ),
                    DrawingLayer(docId: widget.docId!, page: 0),
                  ],
                ),
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

