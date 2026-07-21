import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/nd_colors.dart';
import 'auth_service.dart';

/// E-posta ile giriş/kayıt alt sayfası (parolasız 6 haneli kod). Onboarding ve
/// Ayarlar'dan çağrılır. Başarılı girişte `true` döner.
Future<bool> showSignInSheet(BuildContext context, WidgetRef ref) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.nd.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => const _SignInSheet(),
  );
  return ok ?? false;
}

class _SignInSheet extends ConsumerStatefulWidget {
  const _SignInSheet();

  @override
  ConsumerState<_SignInSheet> createState() => _SignInSheetState();
}

enum _Step { email, code, name }

class _SignInSheetState extends ConsumerState<_SignInSheet> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _name = TextEditingController();

  _Step _step = _Step.email;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  bool get _isEn => context.isEn;

  Future<void> _run(Future<void> Function() action, {VoidCallback? onOk}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (!mounted) return;
      setState(() => _busy = false);
      onOk?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = authErrorText(e, en: _isEn);
      });
    }
  }

  void _sendCode() {
    final email = _email.text.trim();
    if (!email.contains('@') || email.length < 5) {
      setState(() => _error =
          context.t('Geçerli bir e-posta girin.', 'Enter a valid email.'));
      return;
    }
    _run(() => ref.read(authServiceProvider).sendCode(email),
        onOk: () => setState(() => _step = _Step.code));
  }

  void _verify() {
    final code = _code.text.trim();
    if (code.length < 6) {
      setState(() => _error =
          context.t('6 haneli kodu girin.', 'Enter the 6-digit code.'));
      return;
    }
    _run(() => ref.read(authServiceProvider).verifyCode(_email.text, code),
        onOk: () {
      // Ad girilmemişse ad adımı, yoksa bitir.
      if (ref.read(needsDisplayNameProvider)) {
        setState(() => _step = _Step.name);
      } else {
        Navigator.of(context).pop(true);
      }
    });
  }

  void _saveName() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      Navigator.of(context).pop(true); // ad opsiyonel
      return;
    }
    _run(() => ref.read(authServiceProvider).setDisplayName(name),
        onOk: () => Navigator.of(context).pop(true));
  }

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(22, 16, 22, 22 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: nd.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Icon(
            switch (_step) {
              _Step.email => Icons.mail_outline_rounded,
              _Step.code => Icons.password_rounded,
              _Step.name => Icons.person_outline_rounded,
            },
            size: 30,
            color: nd.accent,
          ),
          const SizedBox(height: 12),
          Text(
            switch (_step) {
              _Step.email =>
                context.t('E-posta ile giriş', 'Sign in with email'),
              _Step.code => context.t('Kodu gir', 'Enter the code'),
              _Step.name => context.t('Adın ne olsun?', 'What should we call you?'),
            },
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            switch (_step) {
              _Step.email => context.t(
                  'E-postana 6 haneli bir kod göndereceğiz. Parola yok.',
                  'We’ll send a 6-digit code to your email. No password.'),
              _Step.code => context.t(
                  '${_email.text.trim()} adresine gelen kodu gir.',
                  'Enter the code sent to ${_email.text.trim()}.'),
              _Step.name => context.t(
                  'Ortak notlarda bu ad görünecek (isteğe bağlı).',
                  'This name shows on shared notes (optional).'),
            },
            style: TextStyle(fontSize: 13.5, height: 1.45, color: nd.text2),
          ),
          const SizedBox(height: 18),
          _field(nd),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style: const TextStyle(
                    fontSize: 12.5, color: Color(0xFFD9534F))),
          ],
          const SizedBox(height: 18),
          _primaryButton(nd),
          if (_step == _Step.code) ...[
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: _busy ? null : _sendCode,
                child: Text(context.t('Kodu tekrar gönder', 'Resend code')),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _field(NdColors nd) {
    InputDecoration deco(String hint) => InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: nd.bg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: nd.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: nd.border),
          ),
        );

    switch (_step) {
      case _Step.email:
        return TextField(
          controller: _email,
          autofocus: true,
          enabled: !_busy,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.go,
          onSubmitted: (_) => _sendCode(),
          decoration: deco('ornek@eposta.com'),
        );
      case _Step.code:
        return TextField(
          controller: _code,
          autofocus: true,
          enabled: !_busy,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.go,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onSubmitted: (_) => _verify(),
          style: const TextStyle(
              fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
          decoration: deco('______').copyWith(counterText: ''),
        );
      case _Step.name:
        return TextField(
          controller: _name,
          autofocus: true,
          enabled: !_busy,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _saveName(),
          decoration: deco(context.t('Adın', 'Your name')),
        );
    }
  }

  Widget _primaryButton(NdColors nd) {
    final (label, onTap) = switch (_step) {
      _Step.email => (context.t('Kod gönder', 'Send code'), _sendCode),
      _Step.code => (context.t('Doğrula', 'Verify'), _verify),
      _Step.name => (context.t('Bitir', 'Finish'), _saveName),
    };
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _busy ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: nd.accent,
          foregroundColor: nd.accentFg,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : Text(label,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
