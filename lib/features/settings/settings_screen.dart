import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/collab/collab_config.dart';
import '../../core/i18n/i18n.dart';
import '../../core/theme/nd_colors.dart';
import '../auth/auth_service.dart';
import '../auth/auth_ui.dart';
import '../drawing/color_picker.dart';
import '../drawing/drawing_state.dart';
import '../routines/streaks.dart';
import '../shell/shell_state.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nd = context.nd;
    final mode = ref.watch(themeModeProvider);
    final isDark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final palette = ref.watch(penPaletteProvider);
    final sizeIndex = ref.watch(sizeIndexProvider);
    final isEn = ref.watch(localeProvider).languageCode == 'en';
    final streaksEnabled = ref.watch(streaksEnabledProvider);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
          children: [
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardTitle(context.t('Görünüm', 'Appearance')),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                          child: Text(context.t('Tema', 'Theme'),
                              style: const TextStyle(fontSize: 14))),
                      _Segmented(
                        left: context.t('Açık', 'Light'),
                        right: context.t('Koyu', 'Dark'),
                        rightActive: isDark,
                        onLeft: () => ref
                            .read(themeModeProvider.notifier)
                            .set(ThemeMode.light),
                        onRight: () => ref
                            .read(themeModeProvider.notifier)
                            .set(ThemeMode.dark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                          child: Text(context.t('Dil', 'Language'),
                              style: const TextStyle(fontSize: 14))),
                      _Segmented(
                        left: 'Türkçe',
                        right: 'English',
                        rightActive: isEn,
                        onLeft: () => ref
                            .read(localeProvider.notifier)
                            .set(const Locale('tr')),
                        onRight: () => ref
                            .read(localeProvider.notifier)
                            .set(const Locale('en')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardTitle(context.t('Kalem varsayılanları', 'Pen defaults')),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.t('Kalem renkleri', 'Pen colors'),
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(
                                context.t(
                                    'Çubukta görünecek 3 renk (dokun → değiştir)',
                                    'The 3 colors on the bar (tap to change)'),
                                style:
                                    TextStyle(fontSize: 11.5, color: nd.text2)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          for (var i = 0; i < palette.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: GestureDetector(
                                onTap: () async {
                                  final picked = await showColorGridDialog(
                                      context,
                                      current: palette[i]);
                                  if (picked != null) {
                                    ref
                                        .read(penPaletteProvider.notifier)
                                        .setColor(i, picked);
                                  }
                                },
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: palette[i],
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          Colors.black.withValues(alpha: 0.15),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                          child: Text(context.t('Kalınlık', 'Thickness'),
                              style: const TextStyle(fontSize: 14))),
                      Row(
                        children: [
                          for (var i = 0; i < 3; i++)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: GestureDetector(
                                onTap: () => ref
                                    .read(sizeIndexProvider.notifier)
                                    .state = i,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: sizeIndex == i
                                        ? nd.accent
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Container(
                                    width: [4.0, 7.0, 10.0][i],
                                    height: [4.0, 7.0, 10.0][i],
                                    decoration: BoxDecoration(
                                      color: sizeIndex == i
                                          ? nd.accentFg
                                          : nd.text2,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Card(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.t('Seri ve rozetler', 'Streaks & badges'),
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(
                            context.t(
                                'Rutinlerde 🔥 seri ve 🏅 rozet göster',
                                'Show 🔥 streaks and 🏅 badges on routines'),
                            style:
                                TextStyle(fontSize: 11.5, color: nd.text2)),
                      ],
                    ),
                  ),
                  Switch(
                    value: streaksEnabled,
                    activeColor: nd.accent,
                    onChanged: (v) =>
                        ref.read(streaksEnabledProvider.notifier).set(v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (CollabConfig.enabled) _AccountCard(),
            const SizedBox(height: 12),
            _Card(
              child: Row(
                children: [
                  Expanded(
                      child: Text(context.t('Sürüm', 'Version'),
                          style: const TextStyle(fontSize: 14))),
                  Text('1.0.0',
                      style: TextStyle(fontSize: 13, color: nd.text2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: nd.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: nd.border),
      ),
      child: child,
    );
  }
}

/// Hesap & senkron kartı: giriş yoksa "Giriş yap" (e-posta kodu); girişliyse
/// e-posta + ad + "Çıkış". (Senkronun kendisi Faz 3'te; şimdilik hesap + profil.)
class _AccountCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nd = context.nd;
    final account = ref.watch(accountProvider).valueOrNull;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              context.t('Hesap & senkronizasyon', 'Account & sync'),
              style: const TextStyle(
                  fontSize: 14.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            account == null
                ? context.t(
                    'E-posta ile giriş yap; notların tüm cihazlarında yanında olsun. '
                        'Parola yok — sadece e-postana gelen kod.',
                    'Sign in with email so your notes follow you across devices. '
                        'No password — just a code sent to your email.')
                : context.t(
                    'Giriş yaptın. Cihazlar arası senkron yakında bu hesapla açılacak.',
                    'You’re signed in. Cross-device sync will turn on with this account soon.'),
            style: TextStyle(fontSize: 13.5, height: 1.5, color: nd.text2),
          ),
          const SizedBox(height: 14),
          if (account == null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => showSignInSheet(context, ref),
                icon: const Icon(Icons.mail_outline_rounded, size: 18),
                label: Text(context.t('Giriş yap / Kaydol', 'Sign in / Sign up')),
                style: FilledButton.styleFrom(
                  backgroundColor: nd.accent,
                  foregroundColor: nd.accentFg,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )
          else
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: nd.accent,
                  child: Text(
                    account.displayName.characters.first.toUpperCase(),
                    style: TextStyle(
                        color: nd.accentFg, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w600)),
                      Text(account.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 12.5, color: nd.text2)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => ref.read(authServiceProvider).signOut(),
                  child: Text(context.t('Çıkış', 'Sign out')),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600));
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.left,
    required this.right,
    required this.rightActive,
    required this.onLeft,
    required this.onRight,
  });

  final String left;
  final String right;
  final bool rightActive;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    Widget seg(String label, bool active, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: active ? nd.card : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? nd.text : nd.text2,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: nd.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: nd.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg(left, !rightActive, onLeft),
          const SizedBox(width: 3),
          seg(right, rightActive, onRight),
        ],
      ),
    );
  }
}
