import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/collab/collab_config.dart';
import '../../core/i18n/i18n.dart';
import '../../core/theme/nd_colors.dart';
import '../../data/data_providers.dart';
import '../calendar/calendar_screen.dart';
import '../collab/collab_ui.dart';
import '../drawing/drawing_toolbar.dart';
import '../editor/note_editor_screen.dart';
import '../export/pdf_export.dart';
import '../folders/folders_screen.dart';
import '../ntdl/ntdl_service.dart';
import '../library/library_screen.dart';
import '../pdf/pdf_viewer_screen.dart';
import '../routines/routines_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';
import 'actions.dart';
import 'shell_state.dart';

const _kPhoneBreakpoint = 700.0;

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nd = context.nd;
    final nav = ref.watch(navProvider);
    final isPhone = MediaQuery.sizeOf(context).width < _kPhoneBreakpoint;

    // Geri tuşu: detay/alt ekranlardayken uygulamadan çıkmak yerine geri git.
    final canExit = !nav.isDetail &&
        nav.screen == AppScreen.kutuphane &&
        !nav.drawerOpen &&
        ref.watch(librarySelectionProvider).isEmpty;

    return PopScope(
      canPop: canExit,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final notifier = ref.read(navProvider.notifier);
        if (ref.read(librarySelectionProvider).isNotEmpty) {
          ref.read(librarySelectionProvider.notifier).state = <int>{};
        } else if (nav.drawerOpen) {
          notifier.closeDrawer();
        } else if (nav.isDetail) {
          notifier.back();
        } else if (nav.screen != AppScreen.kutuphane) {
          notifier.go(AppScreen.kutuphane);
        }
      },
      child: Scaffold(
        backgroundColor: nd.bg,
        body: SafeArea(
        child: Stack(
          children: [
            Row(
              children: [
                if (!isPhone)
                  _Sidebar(isDrawer: false, collapsed: nav.sidebarCollapsed),
                const Expanded(child: _MainArea()),
              ],
            ),
            if (isPhone && nav.drawerOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => ref.read(navProvider.notifier).closeDrawer(),
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                ),
              ),
            if (isPhone)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                left: nav.drawerOpen ? 0 : -300,
                top: 0,
                bottom: 0,
                width: 284,
                child: Material(
                  color: nd.sidebar,
                  elevation: nav.drawerOpen ? 16 : 0,
                  child: const _Sidebar(isDrawer: true, collapsed: false),
                ),
              ),
          ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Yan panel ───────────────────────────

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.isDrawer, required this.collapsed});

  final bool isDrawer;
  final bool collapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nd = context.nd;
    final nav = ref.watch(navProvider);
    final folders = ref.watch(folderNamesProvider);
    final docs = ref.watch(documentsProvider).valueOrNull ?? const [];
    final mode = ref.watch(themeModeProvider);
    final isDark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    final showLabels = !collapsed || isDrawer;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      width: isDrawer ? null : (collapsed ? 66 : 248),
      decoration: BoxDecoration(
        color: nd.sidebar,
        border: Border(right: BorderSide(color: nd.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.asset('assets/icon/app_icon.png',
                      width: 30, height: 30, fit: BoxFit.cover),
                ),
                if (showLabels) ...[
                  const SizedBox(width: 10),
                  const Text('notsdaleit',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15.5)),
                ],
              ],
            ),
          ),
          _NavButton(
            icon: Icons.grid_view_outlined,
            label: context.t('Kütüphane', 'Library'),
            active: nav.screen == AppScreen.kutuphane,
            showLabel: showLabels,
            onTap: () => ref.read(navProvider.notifier).go(AppScreen.kutuphane),
          ),
          _NavButton(
            icon: Icons.calendar_today_outlined,
            label: context.t('Takvim', 'Calendar'),
            active: nav.screen == AppScreen.takvim,
            showLabel: showLabels,
            onTap: () => ref.read(navProvider.notifier).go(AppScreen.takvim),
          ),
          _NavButton(
            icon: Icons.repeat,
            label: context.t('Rutinler', 'Routines'),
            active: nav.screen == AppScreen.rutinler,
            showLabel: showLabels,
            onTap: () => ref.read(navProvider.notifier).go(AppScreen.rutinler),
          ),
          _NavButton(
            icon: Icons.search,
            label: context.t('Arama', 'Search'),
            active: nav.screen == AppScreen.arama,
            showLabel: showLabels,
            onTap: () => ref.read(navProvider.notifier).go(AppScreen.arama),
          ),
          _NavButton(
            icon: Icons.folder_outlined,
            label: context.t('Klasörler', 'Folders'),
            active: nav.screen == AppScreen.klasorler,
            showLabel: showLabels,
            onTap: () =>
                ref.read(navProvider.notifier).go(AppScreen.klasorler),
          ),
          _NavButton(
            icon: Icons.tune,
            label: context.t('Ayarlar', 'Settings'),
            active: nav.screen == AppScreen.ayarlar,
            showLabel: showLabels,
            onTap: () => ref.read(navProvider.notifier).go(AppScreen.ayarlar),
          ),
          if (showLabels) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(21, 16, 21, 4),
              child: Text(context.t('KLASÖRLER', 'FOLDERS'),
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: nd.text2)),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final f in folders)
                    _FolderNavButton(
                      name: f,
                      count: docs.where((d) => d.folder == f).length,
                      onTap: () {
                        ref.read(openFoldersProvider.notifier).open(f);
                        ref.read(navProvider.notifier).go(AppScreen.klasorler);
                      },
                    ),
                ],
              ),
            ),
          ] else
            const Spacer(),
          // Tema düğmesi
          Padding(
            padding: const EdgeInsets.all(10),
            child: Material(
              color: nd.card,
              borderRadius: BorderRadius.circular(11),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => ref.read(themeModeProvider.notifier).set(
                    isDark ? ThemeMode.light : ThemeMode.dark),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 11, vertical: 9),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: nd.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isDark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        size: 16,
                        color: nd.text,
                      ),
                      if (showLabels) ...[
                        const SizedBox(width: 11),
                        Text(
                            isDark
                                ? context.t('Açık tema', 'Light theme')
                                : context.t('Koyu tema', 'Dark theme'),
                            style: const TextStyle(
                                fontSize: 13.5, fontWeight: FontWeight.w500)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.showLabel,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      child: Material(
        color: active ? nd.card : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(icon,
                    size: 18, color: active ? nd.text : nd.text2),
                if (showLabel) ...[
                  const SizedBox(width: 11),
                  Text(label,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: active ? nd.text : nd.text2)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FolderNavButton extends StatelessWidget {
  const _FolderNavButton({
    required this.name,
    required this.count,
    required this.onTap,
  });

  final String name;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.folder_outlined, size: 16, color: nd.text2),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: nd.text2)),
                ),
                Text('$count',
                    style: TextStyle(fontSize: 12, color: nd.text2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Ana bölge ───────────────────────────

class _MainArea extends ConsumerWidget {
  const _MainArea();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.watch(navProvider);
    final chromeVisible = ref.watch(chromeVisibleProvider);
    final hideChrome = nav.screen == AppScreen.pdf && !chromeVisible;

    return Column(
      children: [
        ClipRect(
          child: AnimatedAlign(
            alignment: Alignment.topCenter,
            heightFactor: hideChrome ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: const _TopBar(),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOut,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.015),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey('${nav.screen}_${nav.activeDocId}'),
                  child: _screenFor(nav.screen),
                ),
              ),
              if (nav.isDetail)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: nav.screen == AppScreen.pdf ? 74 : 16,
                  child: AnimatedSlide(
                    offset: hideChrome ? const Offset(0, 2.2) : Offset.zero,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width - 20,
                        ),
                        child: const DrawingToolbar(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _screenFor(AppScreen screen) {
    switch (screen) {
      case AppScreen.kutuphane:
        return const LibraryScreen();
      case AppScreen.takvim:
        return const CalendarScreen();
      case AppScreen.rutinler:
        return const RoutinesScreen();
      case AppScreen.arama:
        return const SearchScreen();
      case AppScreen.klasorler:
        return const FoldersScreen();
      case AppScreen.ayarlar:
        return const SettingsScreen();
      case AppScreen.editor:
        return const NoteEditorScreen();
      case AppScreen.pdf:
        return const PdfViewerScreen();
    }
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nd = context.nd;
    final nav = ref.watch(navProvider);
    final isPhone = MediaQuery.sizeOf(context).width < _kPhoneBreakpoint;
    final activeDoc = ref.watch(activeDocumentProvider);

    final title = nav.isDetail
        ? (activeDoc?.title.trim().isEmpty ?? true
            ? context.t('Adsız not', 'Untitled note')
            : activeDoc!.title)
        : switch (nav.screen) {
            AppScreen.kutuphane => context.t('Kütüphane', 'Library'),
            AppScreen.takvim => context.t('Takvim', 'Calendar'),
            AppScreen.rutinler => context.t('Rutinler', 'Routines'),
            AppScreen.arama => context.t('Arama', 'Search'),
            AppScreen.klasorler => context.t('Klasörler', 'Folders'),
            AppScreen.ayarlar => context.t('Ayarlar', 'Settings'),
            _ => '',
          };

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: nd.border)),
      ),
      child: Row(
        children: [
          _IconBtn(
            icon: nav.isDetail ? Icons.arrow_back : Icons.menu,
            onTap: () {
              final notifier = ref.read(navProvider.notifier);
              if (nav.isDetail) {
                notifier.back();
              } else if (isPhone) {
                notifier.toggleDrawer();
              } else {
                notifier.toggleSidebarCollapsed();
              }
            },
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          if (nav.isDetail && activeDoc != null) ...[
            if (activeDoc.sharedId != null) const CollabStatusChip(),
            PopupMenuButton<String>(
              tooltip: context.t('Paylaş', 'Share'),
              color: nd.card,
              icon: Icon(Icons.ios_share, size: 18, color: nd.text2),
              onSelected: (v) {
                if (v == 'pdf') exportDocumentAsPdf(ref, activeDoc);
                if (v == 'ntdl') exportNtdl(ref, activeDoc);
                if (v == 'live') shareLive(context, ref, activeDoc);
                if (v == 'unshare') stopLive(context, ref, activeDoc);
              },
              itemBuilder: (context) => [
                if (CollabConfig.enabled && activeDoc.type == 'not')
                  PopupMenuItem(
                      value: 'live',
                      child: Text(activeDoc.sharedId == null
                          ? context.t('Canlı paylaş', 'Share live')
                          : context.t('Paylaşım kodu', 'Share code'))),
                if (CollabConfig.enabled && activeDoc.sharedId != null)
                  PopupMenuItem(
                      value: 'unshare',
                      child: Text(context.t(
                          'Canlı paylaşımı durdur', 'Stop live sharing'))),
                PopupMenuItem(
                    value: 'pdf',
                    child: Text(context.t('PDF olarak paylaş', 'Share as PDF'))),
                if (activeDoc.type == 'not')
                  PopupMenuItem(
                      value: 'ntdl',
                      child: Text(context.t(
                          'Şablon (.ntdl) paylaş', 'Share template (.ntdl)'))),
              ],
            ),
          ],
          if (nav.screen == AppScreen.kutuphane) ...[
            PopupMenuButton<String>(
              tooltip: context.t('İçe aktar', 'Import'),
              color: nd.card,
              icon: Icon(Icons.attach_file, size: 18, color: nd.text2),
              onSelected: (v) {
                if (v == 'pdf') importPdf(ref);
                if (v == 'ntdl') importNtdlPick(ref);
                if (v == 'join') showJoinDialog(context, ref);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                    value: 'pdf',
                    child: Text(context.t('PDF içe aktar', 'Import PDF'))),
                PopupMenuItem(
                    value: 'ntdl',
                    child: Text(
                        context.t('Şablon (.ntdl) aç', 'Open template (.ntdl)'))),
                if (CollabConfig.enabled)
                  PopupMenuItem(
                      value: 'join',
                      child: Text(context.t(
                          'Ortak nota katıl', 'Join shared note'))),
              ],
            ),
            const SizedBox(width: 6),
            FilledButton(
              onPressed: () => createNote(context, ref),
              style: FilledButton.styleFrom(
                backgroundColor: nd.accent,
                foregroundColor: nd.accentFg,
                shape: const StadiumBorder(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                textStyle: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 16),
                  const SizedBox(width: 6),
                  Text(context.t('Yeni not', 'New note')),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: nd.text2),
        ),
      ),
    );
  }
}
