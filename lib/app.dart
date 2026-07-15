import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'core/i18n/i18n.dart';
import 'core/theme/app_theme.dart';
import 'features/ntdl/ntdl_service.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/shell/actions.dart';
import 'features/shell/home_shell.dart';
import 'features/shell/shell_state.dart';

class NotdaleitApp extends ConsumerWidget {
  const NotdaleitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final onboarded = ref.watch(onboardingDoneProvider);
    return MaterialApp(
      title: 'notsdaleit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      locale: locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr'), Locale('en')],
      home: onboarded
          ? const _IncomingPdfHandler()
          : const OnboardingScreen(),
    );
  }
}

/// "Birlikte aç" / paylaş ile gelen PDF'leri yakalayıp içe aktarır, sonra
/// normal ana ekranı ([HomeShell]) gösterir.
class _IncomingPdfHandler extends ConsumerStatefulWidget {
  const _IncomingPdfHandler();

  @override
  ConsumerState<_IncomingPdfHandler> createState() =>
      _IncomingPdfHandlerState();
}

class _IncomingPdfHandlerState extends ConsumerState<_IncomingPdfHandler> {
  StreamSubscription<List<SharedMediaFile>>? _sub;

  @override
  void initState() {
    super.initState();
    // Uygulama açıkken gelen dosyalar.
    _sub = ReceiveSharingIntent.instance.getMediaStream().listen(
      _handle,
      onError: (_) {},
    );
    // Uygulama bir dosyayla başlatıldıysa.
    ReceiveSharingIntent.instance.getInitialMedia().then((files) {
      _handle(files);
      ReceiveSharingIntent.instance.reset();
    });
  }

  void _handle(List<SharedMediaFile> files) {
    if (files.isEmpty) return;
    final path = files.first.path;
    if (path.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // PDF ise PDF görüntüleyiciye; değilse .ntdl olarak içe aktarmayı dene.
      // (importNtdlFromPath format işaretçisini doğrular; .ntdl değilse sessizce
      // çıkar. Böylece dosya yöneticisi uzantıyı korumasa bile çalışır.)
      if (path.toLowerCase().endsWith('.pdf')) {
        openPdfFromPath(ref, path);
      } else {
        importNtdlFromPath(ref, path);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const HomeShell();
}
