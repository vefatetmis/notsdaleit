import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/nd_colors.dart';
import '../../data/data_providers.dart';
import '../../data/database/database.dart';
import 'lock_service.dart';

/// PIN girme/belirleme diyalogları ve not kilitleme akışları.

/// PIN sorar; doğruysa true döner. [title] ne için sorulduğunu söyler.
Future<bool> askPin(BuildContext context, WidgetRef ref, String title) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => _PinDialog(title: title, verifyWith: ref),
  );
  return ok == true;
}

/// Yeni PIN belirletir (iki kez sorar). Başarılıysa true döner.
Future<bool> setPinFlow(BuildContext context, WidgetRef ref) async {
  final pin = await showDialog<String>(
    context: context,
    builder: (_) => _PinDialog(
      title: context.t('Yeni PIN belirle', 'Set a new PIN'),
      returnPin: true,
    ),
  );
  if (pin == null || !context.mounted) return false;

  final again = await showDialog<String>(
    context: context,
    builder: (_) => _PinDialog(
      title: context.t('PIN’i tekrar gir', 'Enter the PIN again'),
      returnPin: true,
    ),
  );
  if (again == null || !context.mounted) return false;

  if (pin != again) {
    _toast(context, 'PIN’ler eşleşmedi', 'The PINs did not match');
    return false;
  }
  await ref.read(pinSetProvider.notifier).setPin(pin);
  if (context.mounted) {
    _toast(context, 'PIN belirlendi', 'PIN set');
  }
  return true;
}

/// PIN'i kaldırır — önce mevcut PIN sorulur, sonra **kilitli notların kilidi
/// de açılır** (yoksa açılamayan not kalırdı).
Future<void> removePinFlow(BuildContext context, WidgetRef ref) async {
  final ok = await askPin(
      context, ref, context.t('Mevcut PIN', 'Current PIN'));
  if (!ok || !context.mounted) return;

  final repo = ref.read(documentRepositoryProvider);
  final docs = ref.read(documentsProvider).valueOrNull ?? const <Document>[];
  for (final d in docs.where((d) => d.locked)) {
    await repo.setLocked(id: d.id, locked: false);
  }
  await ref.read(pinSetProvider.notifier).clearPin();
  ref.read(unlockedNotesProvider.notifier).state = <int>{};
  if (context.mounted) {
    _toast(context, 'PIN kaldırıldı, notların kilidi açıldı',
        'PIN removed, your notes are unlocked');
  }
}

/// Bir notu kilitler / kilidini açar. PIN yoksa önce belirletir.
Future<void> toggleLock(
    BuildContext context, WidgetRef ref, Document doc) async {
  if (!ref.read(pinSetProvider)) {
    final set = await setPinFlow(context, ref);
    if (!set || !context.mounted) return;
  }

  if (doc.locked) {
    // Kilidi açmak için PIN gerekir.
    final ok = await askPin(
        context, ref, context.t('Kilidi aç', 'Unlock note'));
    if (!ok || !context.mounted) return;
    await ref
        .read(documentRepositoryProvider)
        .setLocked(id: doc.id, locked: false);
    ref.read(unlockedNotesProvider.notifier).state = {
      ...ref.read(unlockedNotesProvider),
      doc.id,
    };
    if (context.mounted) _toast(context, 'Not kilidi açıldı', 'Note unlocked');
    return;
  }

  await ref.read(documentRepositoryProvider).setLocked(id: doc.id, locked: true);
  // Kilitlenen not bu oturumda açık sayılmasın.
  final open = {...ref.read(unlockedNotesProvider)}..remove(doc.id);
  ref.read(unlockedNotesProvider.notifier).state = open;
  if (context.mounted) _toast(context, 'Not kilitlendi', 'Note locked');
}

/// Kilitli bir belge açılmadan önce çağrılır: gerekiyorsa PIN sorar.
/// Açılabilir mi? (kilitli değilse ya da PIN doğruysa true)
Future<bool> ensureUnlocked(
    BuildContext context, WidgetRef ref, Document doc) async {
  if (!doc.locked) return true;
  if (ref.read(unlockedNotesProvider).contains(doc.id)) return true;
  final ok = await askPin(
      context, ref, context.t('Kilitli not', 'Locked note'));
  if (!ok) return false;
  ref.read(unlockedNotesProvider.notifier).state = {
    ...ref.read(unlockedNotesProvider),
    doc.id,
  };
  return true;
}

void _toast(BuildContext context, String tr, String en) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(context.t(tr, en)),
    ));
}

/// PIN giriş kutusu: **6 kutucuk**. Görünmez bir `TextField` tuşları toplar,
/// kutucuklar doldukça dolar; altıncı rakamda kendiliğinden onaylanır (ayrı
/// "Tamam" beklemek gereksiz — uzunluk sabit).
class _PinDialog extends ConsumerStatefulWidget {
  const _PinDialog({
    required this.title,
    this.verifyWith,
    this.returnPin = false,
  });

  final String title;
  final WidgetRef? verifyWith;
  final bool returnPin;

  @override
  ConsumerState<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends ConsumerState<_PinDialog> {
  final _c = TextEditingController();
  final _focus = FocusNode();
  String? _error;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _c.removeListener(_onChanged);
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() => _error = null);
    if (_c.text.length == kPinLength) {
      // Kullanıcı son rakamı görsün diye bir kare bekle.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _submit();
      });
    }
  }

  void _submit() {
    final pin = _c.text;
    if (pin.length != kPinLength) return;
    if (widget.returnPin) {
      Navigator.of(context).pop(pin);
      return;
    }
    if (ref.read(pinSetProvider.notifier).verify(pin)) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = context.t('PIN yanlış', 'Wrong PIN'));
      _c.clear();
      _focus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    final len = _c.text.length;

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Kutucuklar + üstlerinde tuşları toplayan görünmez alan.
          Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < kPinLength; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _PinBox(
                        filled: i < len,
                        active: i == len,
                        error: _error != null,
                      ),
                    ),
                ],
              ),
              // Görünmez: imleç/metin gizli, yalnız klavye girdisi alır.
              SizedBox(
                width: kPinLength * 44,
                height: 52,
                child: TextField(
                  controller: _c,
                  focusNode: _focus,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  maxLength: kPinLength,
                  showCursor: false,
                  style: const TextStyle(color: Colors.transparent),
                  cursorColor: Colors.transparent,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _error ?? context.t('$kPinLength haneli PIN', '$kPinLength-digit PIN'),
            style: TextStyle(
              fontSize: 12.5,
              color: _error != null ? Theme.of(context).colorScheme.error : nd.text2,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.t('Vazgeç', 'Cancel')),
        ),
      ],
    );
  }
}

/// Tek PIN kutucuğu: boş / dolu / sıradaki (vurgulu).
class _PinBox extends StatelessWidget {
  const _PinBox({
    required this.filled,
    required this.active,
    required this.error,
  });

  final bool filled;
  final bool active;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    final border = error
        ? Theme.of(context).colorScheme.error
        : active
            ? nd.accent
            : nd.borderStrong;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: 36,
      height: 46,
      decoration: BoxDecoration(
        color: nd.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: active || error ? 2 : 1),
      ),
      alignment: Alignment.center,
      child: filled
          ? Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: nd.text,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}
