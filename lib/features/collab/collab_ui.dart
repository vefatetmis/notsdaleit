import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/nd_colors.dart';
import '../../data/database/database.dart';
import '../drawing/drawing_state.dart';
import '../shell/shell_state.dart';
import 'collab_service.dart';

/// Supabase hatasını kullanıcıya anlaşılır (ve teşhis koyulabilir) metne çevirir.
String collabErrorText(BuildContext context, Object e) {
  final s = e.toString();
  if (s.contains('Anonymous') || s.contains('anonymous')) {
    return context.t(
        'Sunucuda anonim giriş kapalı. Supabase → Authentication → '
            '"Anonymous sign-ins" açılmalı.',
        'Anonymous sign-ins are disabled on the server '
            '(Supabase → Authentication).');
  }
  if (s.contains('create_shared_note') ||
      s.contains('join_note') ||
      s.contains('schema cache')) {
    return context.t(
        'Sunucu kurulumu eksik: setup.sql betiği SQL Editor\'de '
            'çalıştırılmamış görünüyor.',
        'Server setup incomplete: setup.sql does not seem to have been run.');
  }
  if (s.contains('Invalid API key') || s.contains('invalid') && s.contains('key')) {
    return context.t('API anahtarı geçersiz görünüyor.',
        'The API key looks invalid.');
  }
  if (s.contains('SocketException') ||
      s.contains('Failed host lookup') ||
      s.contains('Connection')) {
    return context.t('İnternet bağlantısı yok görünüyor.',
        'No internet connection.');
  }
  final short = s.length > 140 ? '${s.substring(0, 140)}…' : s;
  return context.t('Paylaşım hatası: $short', 'Share error: $short');
}

/// "Canlı paylaş" akışı: not paylaşımlı değilse sunucuda oluşturur, sonra
/// katılım kodunu gösterir.
Future<void> shareLive(BuildContext context, WidgetRef ref, Document doc) async {
  var code = doc.shareCode;
  if (code == null) {
    try {
      code = await ref.read(collabServiceProvider).shareNote(doc);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            duration: const Duration(seconds: 6),
            content: Text(collabErrorText(context, e))));
      }
      return;
    }
  }
  if (context.mounted) await showShareCodeDialog(context, code);
}

/// Katılım kodunu büyük ve kopyalanabilir biçimde gösterir.
Future<void> showShareCodeDialog(BuildContext context, String code) {
  final nd = context.nd;
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: nd.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: nd.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_alt_outlined, size: 18, color: nd.text),
                const SizedBox(width: 8),
                Text(context.t('Canlı ortak not', 'Live shared note'),
                    style: const TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: nd.bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: nd.borderStrong),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 6,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.t(
                  'Bu kodu paylaşacağın kişiye gönder. O da uygulamada '
                      '"Ortak nota katıl" deyip kodu girsin.',
                  'Send this code to the other person. They tap '
                      '"Join shared note" in the app and enter it.'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.45, color: nd.text2),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              context.t('Kod kopyalandı', 'Code copied'))));
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: Text(context.t('Kopyala', 'Copy')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: nd.accent,
                      foregroundColor: nd.accentFg,
                    ),
                    child: Text(context.t('Tamam', 'Done')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// "Canlı paylaşımı durdur" akışı: onay iste → paylaşımı bırak (sahip siler,
/// üye ayrılır); yerelde kişisel nota döner.
Future<void> stopLive(BuildContext context, WidgetRef ref, Document doc) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.t('Canlı paylaşımı durdur?', 'Stop live sharing?')),
      content: Text(context.t(
          'Bu not artık eşitlenmeyecek. Not ve çizimler cihazında kalır; '
              'katılım kodu geçersiz olur.',
          'This note will stop syncing. It stays on your device; the join '
              'code becomes invalid.')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.t('Vazgeç', 'Cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(context.t('Durdur', 'Stop')),
        ),
      ],
    ),
  );
  if (ok != true) return;
  try {
    await ref.read(collabServiceProvider).unshare(doc);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.t(
              'Canlı paylaşım durduruldu', 'Live sharing stopped'))));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(collabErrorText(context, e))));
    }
  }
}

/// "Ortak nota katıl" diyaloğu: kod girilir, katılınca not açılır.
Future<void> showJoinDialog(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    builder: (context) => const _JoinDialog(),
  );
}

class _JoinDialog extends ConsumerStatefulWidget {
  const _JoinDialog();

  @override
  ConsumerState<_JoinDialog> createState() => _JoinDialogState();
}

class _JoinDialogState extends ConsumerState<_JoinDialog> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.length < 6 || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final docId = await ref.read(collabServiceProvider).joinByCode(code);
      if (!mounted) return;
      Navigator.of(context).pop();
      ref.read(toolProvider.notifier).state = PenTool.yazi;
      ref.read(zoomProvider.notifier).state = 1.0;
      ref.read(navProvider.notifier).openDoc(docId, isPdf: false);
    } catch (e) {
      if (!mounted) return;
      final notFound = e.toString().contains('code_not_found');
      setState(() {
        _busy = false;
        _error = notFound
            ? context.t('Bu kodla bir not bulunamadı.',
                'No note found with this code.')
            : collabErrorText(context, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    return Dialog(
      backgroundColor: nd.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: nd.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.t('Ortak nota katıl', 'Join shared note'),
                style: const TextStyle(
                    fontSize: 15.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              context.t('Paylaşan kişinin gönderdiği 6 haneli kodu gir.',
                  'Enter the 6-character code you received.'),
              style: TextStyle(fontSize: 13, color: nd.text2),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: nd.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: nd.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _join(),
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 4),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                  hintText: 'ABC123',
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: const TextStyle(
                      fontSize: 12.5, color: Color(0xFFE0533D))),
            ],
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  child: Text(context.t('Vazgeç', 'Cancel')),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed:
                      _controller.text.trim().length >= 6 && !_busy ? _join : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: nd.accent,
                    foregroundColor: nd.accentFg,
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.t('Katıl', 'Join')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Üst barda paylaşımlı not açıkken görünen durum rozeti.
class CollabStatusChip extends ConsumerWidget {
  const CollabStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nd = context.nd;
    final status = ref.watch(collabStatusProvider);
    if (status == null) return const SizedBox.shrink();

    final (color, label) = switch (status) {
      CollabStatus.live => (
          const Color(0xFF16A34A),
          context.t('Canlı', 'Live')
        ),
      CollabStatus.connecting => (
          const Color(0xFFF0B429),
          context.t('Bağlanıyor…', 'Connecting…')
        ),
      CollabStatus.offline => (
          const Color(0xFFE0533D),
          context.t('Çevrimdışı', 'Offline')
        ),
    };

    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: nd.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: nd.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: nd.text2)),
        ],
      ),
    );
  }
}
