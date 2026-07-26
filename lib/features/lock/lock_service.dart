import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shell/shell_state.dart';

/// **Not kilidi (PIN).**
///
/// Kilitli notlar açılırken PIN sorulur ve kütüphanede içerikleri gizlenir.
///
/// ### Bunun ne olduğu — ve ne OLMADIĞI
/// Bu bir **arayüz kilididir, şifreleme değildir.** Not gövdesi veritabanında
/// düz metin olarak durur; cihaza fiziksel erişimi olan (ya da yedeği açan)
/// biri içeriği görebilir. Amacı, telefonu eline alan birinin notu kazara/
/// meraktan açmasını engellemek. Gerçek gizlilik için gövdenin şifrelenmesi
/// gerekir — bu ayrı ve büyük bir iş (yedek/paylaşım/arama hepsi etkilenir).
///
/// PIN'in kendisi saklanmaz: rastgele bir tuz + SHA-256 özeti saklanır.

const _kHashKey = 'lockPinHash';
const _kSaltKey = 'lockPinSalt';

String _hash(String pin, String salt) =>
    sha256.convert(utf8.encode('$salt:$pin')).toString();

String _newSalt() {
  final r = Random.secure();
  return List<int>.generate(16, (_) => r.nextInt(256))
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
}

/// Bir PIN belirlenmiş mi? (Belirlenmeden not kilitlenemez.)
final pinSetProvider = NotifierProvider<PinNotifier, bool>(PinNotifier.new);

class PinNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.read(sharedPrefsProvider);
    return (prefs.getString(_kHashKey) ?? '').isNotEmpty;
  }

  /// PIN belirler/değiştirir.
  Future<void> setPin(String pin) async {
    final prefs = ref.read(sharedPrefsProvider);
    final salt = _newSalt();
    await prefs.setString(_kSaltKey, salt);
    await prefs.setString(_kHashKey, _hash(pin, salt));
    state = true;
  }

  /// PIN'i kaldırır. Çağıran taraf, kilitli notların kilidini de açmalıdır
  /// (yoksa açılamayan not kalır) — bkz. `lock_ui.removePinFlow`.
  Future<void> clearPin() async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.remove(_kHashKey);
    await prefs.remove(_kSaltKey);
    state = false;
  }

  /// Girilen PIN doğru mu?
  bool verify(String pin) {
    final prefs = ref.read(sharedPrefsProvider);
    final hash = prefs.getString(_kHashKey) ?? '';
    final salt = prefs.getString(_kSaltKey) ?? '';
    if (hash.isEmpty || salt.isEmpty) return false;
    return _hash(pin, salt) == hash;
  }
}

/// Bu oturumda PIN'i doğrulanmış (açılmış) not id'leri. Uygulama kapanınca
/// sıfırlanır — kalıcı olsaydı kilit anlamını yitirirdi.
final unlockedNotesProvider = StateProvider<Set<int>>((ref) => <int>{});
