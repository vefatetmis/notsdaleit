import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/shell/shell_state.dart';

/// Basit iki dilli (TR/EN) yerelleştirme. Her metin kullanım yerinde
/// `context.t('Türkçe', 'English')` ile verilir; ayrı ARB/kod üretimi yok.
extension I18nX on BuildContext {
  bool get isEn =>
      Localizations.maybeLocaleOf(this)?.languageCode == 'en';

  /// Aktif dile göre metni seç.
  String t(String tr, String en) => isEn ? en : tr;
}

/// Uygulama dili (kalıcı). Varsayılan: Türkçe.
class LocaleNotifier extends Notifier<Locale> {
  static const _key = 'appLocale';

  @override
  Locale build() {
    final saved = ref.read(sharedPrefsProvider).getString(_key);
    return saved == 'en' ? const Locale('en') : const Locale('tr');
  }

  void set(Locale locale) {
    state = locale;
    ref.read(sharedPrefsProvider).setString(_key, locale.languageCode);
  }
}

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

/// Onboarding (tanıtım) tamamlandı mı? (kalıcı) — ilk açılışta gösterilir.
class OnboardingNotifier extends Notifier<bool> {
  static const _key = 'onboardingDone';

  @override
  bool build() => ref.read(sharedPrefsProvider).getBool(_key) ?? false;

  void complete() {
    state = true;
    ref.read(sharedPrefsProvider).setBool(_key, true);
  }
}

final onboardingDoneProvider =
    NotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);
