import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';

import '../../core/theme/nd_colors.dart';
import '../../data/data_providers.dart';
import '../drawing/drawing_layer.dart';
import '../drawing/drawing_state.dart';
import '../shell/shell_state.dart';

/// Gerçek PDF görüntüleyici. Sayfalar pdfx ile görüntüye render edilir; her
/// sayfanın üstünde çizim katmanı vardır. Yakınlaştırma sayfa genişliğini
/// ölçekler; sayfa görünümden genişse yatay kaydırılır.
class PdfViewerScreen extends ConsumerStatefulWidget {
  const PdfViewerScreen({super.key});

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  PdfDocument? _doc;
  int _pageCount = 1;
  double _aspect = 1.414;
  String? _error;
  final Map<String, Future<Uint8List?>> _cache = {};
  final ScrollController _vController = ScrollController();

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final doc = ref.read(activeDocumentProvider);
    final path = doc?.filePath;
    if (path == null) {
      setState(() => _error = 'PDF dosyası bulunamadı.');
      return;
    }
    try {
      final pdf = await PdfDocument.openFile(path);
      final first = await pdf.getPage(1);
      final aspect = first.height / first.width;
      await first.close();
      if (!mounted) {
        await pdf.close();
        return;
      }
      setState(() {
        _doc = pdf;
        _pageCount = pdf.pagesCount;
        _aspect = aspect == 0 ? 1.414 : aspect;
      });
    } catch (e) {
      setState(() => _error = 'PDF açılamadı: $e');
    }
  }

  @override
  void dispose() {
    // Çıkarken çubukları geri göster (başka ekranlarda gizli kalmasın).
    ref.read(chromeVisibleProvider.notifier).state = true;
    _vController.dispose();
    _doc?.close();
    super.dispose();
  }

  void _setChrome(bool visible) {
    final notifier = ref.read(chromeVisibleProvider.notifier);
    if (notifier.state != visible) notifier.state = visible;
  }

  bool _onScrollChrome(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    if (n is UserScrollNotification) {
      if (n.direction == ScrollDirection.reverse) {
        _setChrome(false); // aşağı kaydırma → gizle
      } else if (n.direction == ScrollDirection.forward) {
        _setChrome(true); // yukarı kaydırma → göster
      }
    } else if (n is ScrollEndNotification) {
      _setChrome(true); // durunca → göster
    }
    return false;
  }

  void _panScroll(double dy) {
    if (!_vController.hasClients) return;
    final pos = _vController.position;
    _vController.jumpTo(
      (_vController.offset - dy).clamp(0.0, pos.maxScrollExtent),
    );
  }

  Future<Uint8List?> _render(int index, int widthPx) {
    final key = '$index@$widthPx';
    return _cache.putIfAbsent(key, () async {
      final doc = _doc;
      if (doc == null) return null;
      final page = await doc.getPage(index + 1);
      try {
        final image = await page.render(
          width: widthPx.toDouble(),
          height: widthPx * page.height / page.width,
          format: PdfPageImageFormat.png,
          backgroundColor: '#FFFFFF',
        );
        return image?.bytes;
      } finally {
        await page.close();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    final zoom = ref.watch(zoomProvider);
    final penActive = ref.watch(toolProvider).isPen;
    final chromeVisible = ref.watch(chromeVisibleProvider);

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(_error!,
              textAlign: TextAlign.center, style: TextStyle(color: nd.text2)),
        ),
      );
    }
    if (_doc == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final lockedPhysics =
        penActive ? const NeverScrollableScrollPhysics() : null;

    return Column(
      children: [
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScrollChrome,
            child: LayoutBuilder(
              builder: (context, c) {
              final dpr = MediaQuery.devicePixelRatioOf(context);
              final baseW = (c.maxWidth - 32).clamp(120.0, 680.0);
              final pageW = baseW * zoom;
              final contentW = math.max(pageW + 24, c.maxWidth);
              // Render çözünürlüğünü 100px basamaklara yuvarla; pinch sırasında
              // sürekli yeniden render olmasın.
              final widthPx =
                  ((pageW * dpr / 100).round() * 100).clamp(200, 3000);

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: lockedPhysics,
                child: SizedBox(
                  width: contentW,
                  child: ListView.builder(
                    controller: _vController,
                    physics: penActive
                        ? const NeverScrollableScrollPhysics()
                        : const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _pageCount,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Center(
                          child: SizedBox(
                            width: pageW,
                            height: pageW * _aspect,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: nd.borderStrong),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.07),
                                    blurRadius: 14,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    FutureBuilder<Uint8List?>(
                                      future: _render(index, widthPx),
                                      builder: (context, snap) {
                                        if (snap.data == null) {
                                          return const Center(
                                            child: SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2),
                                            ),
                                          );
                                        }
                                        return Image.memory(
                                          snap.data!,
                                          fit: BoxFit.fill,
                                          gaplessPlayback: true,
                                        );
                                      },
                                    ),
                                    Positioned.fill(
                                      child: DrawingLayer(
                                        docId: ref
                                            .read(navProvider)
                                            .activeDocId!,
                                        page: index,
                                        onPanScroll: _panScroll,
                                        onPinch: (scale) {
                                          final z =
                                              (ref.read(zoomProvider) * scale)
                                                  .clamp(0.5, 3.0);
                                          ref
                                              .read(zoomProvider.notifier)
                                              .state = z;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          ),
        ),
        ClipRect(
          child: AnimatedAlign(
            alignment: Alignment.topCenter,
            heightFactor: chromeVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: _BottomBar(pageCount: _pageCount, zoom: zoom),
          ),
        ),
      ],
    );
  }
}

/// Alt bar: sayfa sayısı + yakınlaştırma kontrolleri.
class _BottomBar extends ConsumerWidget {
  const _BottomBar({required this.pageCount, required this.zoom});

  final int pageCount;
  final double zoom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nd = context.nd;

    void setZoom(double z) => ref.read(zoomProvider.notifier).state =
        (z.clamp(0.5, 3.0) * 100).roundToDouble() / 100;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      decoration: BoxDecoration(
        color: nd.bg,
        border: Border(top: BorderSide(color: nd.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$pageCount sayfa',
              style: TextStyle(fontSize: 12.5, color: nd.text2)),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: nd.card,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: nd.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.remove, size: 16),
                  color: nd.text2,
                  onPressed: () => setZoom(zoom - 0.25),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    '${(zoom * 100).round()}%',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add, size: 16),
                  color: nd.text2,
                  onPressed: () => setZoom(zoom + 0.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
