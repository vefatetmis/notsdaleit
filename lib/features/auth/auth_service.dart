import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/collab/collab_config.dart';

/// Giriş yapmış (kalıcı, anonim olmayan) hesap. Görünen ad auth kullanıcı
/// metadata'sında saklanır (Faz 1'de ayrı profiles tablosu gerekmez; başka
/// kullanıcıların adı görmesi Faz 2'de profiles tablosuyla gelecek).
class NdAccount {
  const NdAccount({required this.email, required this.displayName});
  final String email;
  final String displayName;
}

NdAccount? _accountFrom(User? u) {
  if (u == null || u.isAnonymous) return null;
  final email = u.email;
  if (email == null || email.isEmpty) return null;
  final name = (u.userMetadata?['display_name'] as String?)?.trim();
  return NdAccount(
    email: email,
    displayName: (name == null || name.isEmpty) ? email.split('@').first : name,
  );
}

/// Oturum durumu akışı — giriş/çıkışta güncellenir. `null` = giriş yok.
final accountProvider = StreamProvider<NdAccount?>((ref) async* {
  if (!CollabConfig.enabled) {
    yield null;
    return;
  }
  final auth = Supabase.instance.client.auth;
  yield _accountFrom(auth.currentUser);
  await for (final _ in auth.onAuthStateChange) {
    yield _accountFrom(auth.currentUser);
  }
});

/// Görünen adın ayarlanması gerekiyor mu? (giriş var ama ad boş → onboarding
/// akışında ad adımı gösterilir.)
final needsDisplayNameProvider = Provider<bool>((ref) {
  final acc = ref.watch(accountProvider).valueOrNull;
  if (acc == null) return false;
  // displayName e-postanın kullanıcı adına düşmüşse gerçek ad girilmemiş demek.
  return acc.displayName == acc.email.split('@').first;
});

class AuthService {
  SupabaseClient get _c => Supabase.instance.client;

  bool get _isAnon => _c.auth.currentUser?.isAnonymous ?? false;

  /// E-postaya 6 haneli kod gönderir. Anonim oturum varsa onu kalıcı hesaba
  /// yükseltmek üzere e-posta değişikliği kodu gönderir (uid korunur →
  /// mevcut collab verisi kaybolmaz).
  Future<void> sendCode(String email) async {
    final e = email.trim();
    if (_isAnon) {
      await _c.auth.updateUser(UserAttributes(email: e));
    } else {
      await _c.auth.signInWithOtp(email: e, shouldCreateUser: true);
    }
  }

  /// Kodu doğrular; başarılıysa oturum kalıcı e-posta hesabına geçer.
  /// Anonim yükseltme → emailChange. Yeni/mevcut kullanıcıda kod hangi
  /// şablondan geldiyse tipi değişebildiği için (email OTP vs "Confirm signup")
  /// email → başarısızsa signup tipiyle tekrar denenir.
  Future<void> verifyCode(String email, String code) async {
    final e = email.trim();
    final t = code.trim();
    if (_isAnon) {
      await _c.auth
          .verifyOTP(email: e, token: t, type: OtpType.emailChange);
      return;
    }
    try {
      await _c.auth.verifyOTP(email: e, token: t, type: OtpType.email);
    } on AuthException catch (err) {
      final low = err.message.toLowerCase();
      final tokenIssue = low.contains('token') ||
          low.contains('otp') ||
          low.contains('invalid') ||
          low.contains('expired');
      if (tokenIssue) {
        await _c.auth.verifyOTP(email: e, token: t, type: OtpType.signup);
      } else {
        rethrow;
      }
    }
  }

  Future<void> setDisplayName(String name) async {
    await _c.auth.updateUser(
      UserAttributes(data: {'display_name': name.trim()}),
    );
  }

  Future<void> signOut() => _c.auth.signOut();
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Auth hatasını kullanıcıya anlaşılır Türkçe/İngilizce metne çevirir.
String authErrorText(Object error, {required bool en}) {
  final msg = error is AuthException ? error.message : error.toString();
  final low = msg.toLowerCase();
  if (low.contains('invalid') &&
      (low.contains('token') || low.contains('otp') || low.contains('code'))) {
    return en
        ? 'The code is wrong or expired. Request a new one.'
        : 'Kod yanlış veya süresi dolmuş. Yeni kod isteyin.';
  }
  if (low.contains('expired')) {
    return en
        ? 'The code expired. Request a new one.'
        : 'Kodun süresi doldu. Yeni kod isteyin.';
  }
  if (low.contains('rate') || low.contains('too many') || low.contains('60')) {
    return en
        ? 'Too many attempts. Wait a bit and try again.'
        : 'Çok fazla deneme. Biraz bekleyip tekrar deneyin.';
  }
  if (low.contains('signups') || low.contains('disabled') || low.contains('not allowed')) {
    return en
        ? 'Email sign-in is disabled in the project settings.'
        : 'Proje ayarlarında e-posta girişi kapalı.';
  }
  if (low.contains('network') ||
      low.contains('socket') ||
      low.contains('failed host') ||
      low.contains('connection')) {
    return en ? 'No internet connection.' : 'İnternet bağlantısı yok.';
  }
  if (low.contains('email') && low.contains('invalid')) {
    return en ? 'Enter a valid email address.' : 'Geçerli bir e-posta girin.';
  }
  return en ? 'Sign-in failed: $msg' : 'Giriş başarısız: $msg';
}
