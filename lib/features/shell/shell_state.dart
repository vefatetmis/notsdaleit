import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// main() içinde gerçek örnekle override edilir.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider override edilmeli'),
);

/// Uygulamadaki ekranlar. Tasarım tek kabuk içinde ekran değiştirir
/// (Navigator push yerine durum tabanlı geçiş).
enum AppScreen {
  kutuphane,
  takvim,
  rutinler,
  arama,
  klasorler,
  ayarlar,
  editor,
  pdf,
}

@immutable
class NavState {
  const NavState({
    this.screen = AppScreen.kutuphane,
    this.mainScreen = AppScreen.kutuphane,
    this.activeDocId,
    this.drawerOpen = false,
    this.sidebarCollapsed = false,
  });

  final AppScreen screen;
  final AppScreen mainScreen; // detaydan (editör/pdf) dönülecek ana ekran
  final int? activeDocId;
  final bool drawerOpen; // telefon: çekmece açık mı
  final bool sidebarCollapsed; // masaüstü: yan panel daraltılmış mı

  bool get isDetail => screen == AppScreen.editor || screen == AppScreen.pdf;

  NavState copyWith({
    AppScreen? screen,
    AppScreen? mainScreen,
    int? activeDocId,
    bool clearDoc = false,
    bool? drawerOpen,
    bool? sidebarCollapsed,
  }) {
    return NavState(
      screen: screen ?? this.screen,
      mainScreen: mainScreen ?? this.mainScreen,
      activeDocId: clearDoc ? null : (activeDocId ?? this.activeDocId),
      drawerOpen: drawerOpen ?? this.drawerOpen,
      sidebarCollapsed: sidebarCollapsed ?? this.sidebarCollapsed,
    );
  }
}

class NavNotifier extends Notifier<NavState> {
  @override
  NavState build() => const NavState();

  void go(AppScreen screen) {
    state = state.copyWith(
      screen: screen,
      mainScreen: screen,
      drawerOpen: false,
      clearDoc: true,
    );
  }

  void openDoc(int id, {required bool isPdf}) {
    state = state.copyWith(
      screen: isPdf ? AppScreen.pdf : AppScreen.editor,
      activeDocId: id,
      drawerOpen: false,
    );
  }

  void back() {
    state = state.copyWith(screen: state.mainScreen, clearDoc: true);
  }

  void toggleDrawer() => state = state.copyWith(drawerOpen: !state.drawerOpen);
  void closeDrawer() => state = state.copyWith(drawerOpen: false);
  void toggleSidebarCollapsed() =>
      state = state.copyWith(sidebarCollapsed: !state.sidebarCollapsed);
}

final navProvider = NotifierProvider<NavNotifier, NavState>(NavNotifier.new);

/// Tema kipi. Varsayılan: açık (beyaz). Seçim kalıcıdır (SharedPreferences).
class ThemeNotifier extends Notifier<ThemeMode> {
  static const _key = 'themeMode';

  @override
  ThemeMode build() {
    final saved = ref.read(sharedPrefsProvider).getString(_key);
    return switch (saved) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.light, // varsayılan beyaz
    };
  }

  void set(ThemeMode mode) {
    state = mode;
    ref.read(sharedPrefsProvider).setString(_key, mode.name);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

/// PDF görüntülerken üst/alt çubukların görünürlüğü. Aşağı kaydırınca gizlenir,
/// kaydırma durunca ya da yukarı kaydırınca geri gelir.
final chromeVisibleProvider = StateProvider<bool>((ref) => true);

/// Kütüphane filtre çipi: 'tumu' | 'not' | 'pdf'.
final libraryFilterProvider = StateProvider<String>((ref) => 'tumu');

/// Kütüphanede toplu seçim (uzun bas → seçim modu). Boş küme = normal mod.
final librarySelectionProvider = StateProvider<Set<int>>((ref) => <int>{});

/// Arama metni.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Klasörler ekranında açık (genişletilmiş) klasörler.
class OpenFoldersNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {'Ders Notları'};

  void toggle(String name) {
    final next = {...state};
    if (!next.remove(name)) next.add(name);
    state = next;
  }

  void open(String name) => state = {...state, name};
}

final openFoldersProvider =
    NotifierProvider<OpenFoldersNotifier, Set<String>>(OpenFoldersNotifier.new);

/// Kullanıcının eklediği (henüz belgesi olmayan) klasörler. Tasarımdaki gibi
/// oturum boyunca yaşar.
class ExtraFoldersNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void add(String name) {
    final n = name.trim();
    if (n.isEmpty || state.contains(n)) return;
    state = [...state, n];
  }

  void remove(String name) {
    if (!state.contains(name)) return;
    state = state.where((e) => e != name).toList();
  }
}

final extraFoldersProvider =
    NotifierProvider<ExtraFoldersNotifier, List<String>>(
        ExtraFoldersNotifier.new);
