import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/nd_colors.dart';
import '../../data/data_providers.dart';
import '../../data/database/database.dart';
import '../forms/insert_image.dart';

/// Notun üzerindeki **serbest konumlu görseller**.
///
/// Görseller çizimlerle aynı koordinat uzayındadır (sayfa genişliğine göre
/// normalize, tüm sayfalar tek düşey düzlem) — yani görsel de çizim gibi
/// sayfanın istenen yerinde durur ve **not form notuna dönüşmez**.
///
/// Katman `_PagesClipper` içinde çizilir, böylece sayfa kartlarının dışına
/// (kenar boşluklarına) taşan bir görsel görünmez ve oraya bırakılamaz.
///
/// Etkileşim yalnız **yazı/el modunda** açıktır; kalem modunda katman
/// dokunuşları geçirir ki çizim yapılabilsin.
class ImageLayer extends ConsumerStatefulWidget {
  const ImageLayer({
    super.key,
    required this.docId,
    required this.width,
    required this.imagesDirPath,
    required this.interactive,
  });

  final int docId;

  /// Sayfa genişliği (px) — normalize koordinatları piksele çevirir.
  final double width;
  final String? imagesDirPath;
  final bool interactive;

  @override
  ConsumerState<ImageLayer> createState() => _ImageLayerState();
}

class _ImageLayerState extends ConsumerState<ImageLayer> {
  // Sürükleme sırasında canlı önizleme (kaydetme parmak kalkınca yapılır —
  // her karede veritabanına yazmak gereksiz).
  int? _dragId;
  Offset _dragDelta = Offset.zero;
  double _resizeDelta = 0;

  @override
  Widget build(BuildContext context) {
    final images = ref.watch(activeImagesProvider).valueOrNull ?? const [];
    if (images.isEmpty) return const SizedBox.shrink();
    final selected = ref.watch(selectedImageProvider);
    final w = widget.width;

    return Stack(
      children: [
        for (final img in images)
          _positioned(img, w, selected == img.id),
      ],
    );
  }

  Widget _positioned(NoteImage img, double pageW, bool isSelected) {
    final nd = context.nd;
    final live = _dragId == img.id;
    final iw = ((img.w + (live ? _resizeDelta : 0)) * pageW)
        .clamp(pageW * 0.08, pageW);
    final ih = iw * img.aspect;
    final left = img.x * pageW + (live ? _dragDelta.dx : 0);
    final top = img.y * pageW + (live ? _dragDelta.dy : 0);

    final dirPath = widget.imagesDirPath;
    final file = dirPath == null ? null : imageFileFor(dirPath, img.file);

    Widget picture = ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: file != null && file.existsSync()
          ? Image.file(file, fit: BoxFit.fill,
              errorBuilder: (_, __, ___) => _missing(nd))
          : _missing(nd),
    );

    if (isSelected) {
      picture = Container(
        decoration: BoxDecoration(
          border: Border.all(color: nd.accent, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(2),
        child: picture,
      );
    }

    return Positioned(
      left: left,
      top: top,
      width: iw,
      height: ih,
      child: IgnorePointer(
        ignoring: !widget.interactive,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => ref.read(selectedImageProvider.notifier).state =
              isSelected ? null : img.id,
          onPanStart: (_) {
            ref.read(selectedImageProvider.notifier).state = img.id;
            setState(() {
              _dragId = img.id;
              _dragDelta = Offset.zero;
              _resizeDelta = 0;
            });
          },
          onPanUpdate: (d) => setState(() => _dragDelta += d.delta),
          onPanEnd: (_) => _commitMove(img, pageW),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: picture),
              if (isSelected) ...[
                // Sağ-alt köşe: boyutlandırma tutamağı.
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (_) => setState(() {
                      _dragId = img.id;
                      _dragDelta = Offset.zero;
                      _resizeDelta = 0;
                    }),
                    onPanUpdate: (d) =>
                        setState(() => _resizeDelta += d.delta.dx / pageW),
                    onPanEnd: (_) => _commitResize(img, pageW),
                    child: _handle(nd, Icons.open_in_full),
                  ),
                ),
                // Sağ-üst köşe: sil.
                Positioned(
                  right: -10,
                  top: -10,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _confirmDelete(img),
                    child: _handle(nd, Icons.close, danger: true),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _handle(NdColors nd, IconData icon, {bool danger = false}) => Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: danger ? Colors.red.shade600 : nd.accent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(icon, size: 14, color: Colors.white),
      );

  Widget _missing(NdColors nd) => Container(
        color: nd.hover,
        alignment: Alignment.center,
        child: Icon(Icons.broken_image_outlined, color: nd.text2, size: 26),
      );

  void _commitMove(NoteImage img, double pageW) {
    final nx = (img.x + _dragDelta.dx / pageW).clamp(0.0, 1.0 - img.w);
    final ny = img.y + _dragDelta.dy / pageW;
    setState(() {
      _dragId = null;
      _dragDelta = Offset.zero;
    });
    ref.read(noteImageRepositoryProvider).setRect(img.id, x: nx, y: ny);
  }

  void _commitResize(NoteImage img, double pageW) {
    // Genişlik 8%–100% arasında; sayfadan taşmaması için x'e göre sınırlanır.
    final nw = (img.w + _resizeDelta).clamp(0.08, 1.0 - img.x);
    setState(() {
      _dragId = null;
      _resizeDelta = 0;
    });
    ref.read(noteImageRepositoryProvider).setRect(img.id, w: nw);
  }

  Future<void> _confirmDelete(NoteImage img) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.t('Görsel silinsin mi?', 'Delete image?')),
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
    ref.read(selectedImageProvider.notifier).state = null;
    await ref.read(noteImageRepositoryProvider).delete(img.id);
  }
}
