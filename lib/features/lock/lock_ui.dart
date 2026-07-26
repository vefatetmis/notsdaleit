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

/// PIN giriş kutusu. [returnPin] true ise girilen PIN döner (belirleme akışı),
/// aksi hâlde doğrulanır ve bool döner.
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
  String? _error;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = _c.text.trim();
    if (pin.length < 4) {
      setState(() => _error = context.t(
          'PIN en az 4 rakam olmalı', 'The PIN must be at least 4 digits'));
      return;
    }
    if (widget.returnPin) {
      Navigator.of(context).pop(pin);
      return;
    }
    if (ref.read(pinSetProvider.notifier).verify(pin)) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = context.t('PIN yanlış', 'Wrong PIN'));
      _c.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _c,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 8,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: '••••',
              counterText: '',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.t('4–8 rakam', '4–8 digits'),
            style: TextStyle(fontSize: 12, color: nd.text2),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.t('Vazgeç', 'Cancel')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(context.t('Tamam', 'OK')),
        ),
      ],
    );
  }
}
