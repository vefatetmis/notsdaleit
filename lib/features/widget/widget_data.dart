import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/i18n.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/note_text.dart';
import '../../data/data_providers.dart';
import '../../data/database/database.dart';
import '../routines/streaks.dart';
import '../shell/shell_state.dart';

/// Ana ekran widget'larının **verisi**: uygulama → widget yönü.
///
/// Native taraf veritabanını okuyamaz (drift Dart'ta), bu yüzden uygulama
/// açıkken küçük bir JSON anlık görüntü üretilip `setWidgetData` ile Kotlin'e
/// yollanır; [WidgetSyncRunner] bunu veri her değiştiğinde tekrarlar.
/// Ters yön (widget'tan gelen rutin işaretleri) [drainPendingRoutineToggles].
///
/// **Neden paket yok:** `home_widget` eklemek yeni bir Kotlin sürüm bağımlılığı
/// demekti (eklentiler 1.9.25'e sabit, bkz. CLAUDE.md); ihtiyacımız olan tek
/// şey bu kanal.
const widgetChannel = MethodChannel('notsdaleit/widget');

/// Widget'ta gösterilecek en fazla belge (4×2'ye sığan satır sayısı).
const _kMaxNotes = 4;

/// Native tarafa yollanan rutin sayısı üst sınırı — hangisinin bugün planlı
/// olduğu orada hesaplanır (gece yarısı uygulama kapalıyken de doğru olsun
/// diye), o yüzden hepsi gider.
const _kMaxRoutines = 30;

DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Gece yarısından dakika → "07:00" (rutin hatırlatıcı saati). Hatırlatıcı
/// yoksa boş dize — widget o zaman saat sütununu boş bırakır.
String _hhmm(int? minutes) {
  if (minutes == null) return '';
  final h = (minutes ~/ 60).toString().padLeft(2, '0');
  final m = (minutes % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Widget'lara gönderilecek anlık görüntüyü üretir.
///
/// [dark] tema **uygulamanın** seçiminden gelir (sistemden değil) — widget
/// uygulamayla aynı görünsün diye; ThemeMode.system'de çağıran platformun
/// parlaklığını çözer.
String buildWidgetPayload(WidgetRef ref, {required bool dark}) {
  return encodeWidgetPayload(
    dark: dark,
    en: ref.watch(localeProvider).languageCode == 'en',
    streaks: ref.watch(streaksEnabledProvider),
    routines: ref.watch(routinesProvider).valueOrNull ?? const <Routine>[],
    checks:
        ref.watch(routineChecksProvider).valueOrNull ?? const <RoutineCheck>[],
    docs: ref.watch(documentsProvider).valueOrNull ?? const <Document>[],
    now: DateTime.now(),
  );
}

/// Anlık görüntünün **saf** hâli (test edilebilir).
///
/// Alan adları native tarafla (`WidgetStore.parse`) birebir eşleşmeli — burada
/// bir ad değişirse widget sessizce boşalır.
String encodeWidgetPayload({
  required bool dark,
  required bool en,
  required bool streaks,
  required List<Routine> routines,
  required List<RoutineCheck> checks,
  required List<Document> docs,
  required DateTime now,
}) {
  final today = _dayOnly(now);

  // ── Rutinler ────────────────────────────────────────────────────────────
  final checkedByRoutine = <int, Set<DateTime>>{};
  for (final c in checks) {
    (checkedByRoutine[c.routineId] ??= <DateTime>{}).add(_dayOnly(c.day));
  }

  // Tasarım rutinleri **saate göre** sıralı istiyor; hatırlatıcısı olmayanlar
  // sona düşer (sıra kararlı kalsın diye orada oluşturulma sırası korunur).
  final ordered = [...routines]..sort((a, b) {
      final x = a.remindAt, y = b.remindAt;
      if (x == null && y == null) return 0;
      if (x == null) return 1;
      if (y == null) return -1;
      return x.compareTo(y);
    });

  final routineJson = <Map<String, Object?>>[];
  for (final r in ordered.take(_kMaxRoutines)) {
    final checked = checkedByRoutine[r.id] ?? const <DateTime>{};
    // En son işaretlenen gün: native taraf bunu bugünle karşılaştırır, böylece
    // gece yarısı geçilince işaretler kendiliğinden sıfırlanır.
    DateTime? last;
    for (final d in checked) {
      if (last == null || d.isAfter(last)) last = d;
    }
    routineJson.add({
      'id': r.id,
      'title': r.title,
      'days': r.days,
      'doneDay': last == null ? '' : _iso(last),
      'streak':
          currentStreak(r.days, checked, today, _dayOnly(r.createdAt)),
      'time': _hhmm(r.remindAt),
    });
  }

  // ── Son belgeler ────────────────────────────────────────────────────────
  // Kilitli notlar DIŞARIDA: başlıkları ana ekranda görünmemeli, kilidin
  // amacı bu (widget'tan PIN sorulamaz).
  final noteJson = <Map<String, Object?>>[];
  for (final d in docs) {
    if (d.locked) continue;
    final preview = plainTextFromBody(d.body).trim().replaceAll('\n', ' ');
    noteJson.add({
      'id': d.id,
      'title': d.title.trim(),
      'preview': preview.length > 40 ? preview.substring(0, 40) : preview,
      // Tasarım 2×2 ızgarada "Kişisel · 17 sa" gibi kısa biçim istiyor
      // ("… önce" eki kartı taşırıyor).
      'time': formatRelativeShortIn(d.updatedAt, en: en),
      'folder': d.folder,
      'pdf': d.type == 'pdf',
    });
    if (noteJson.length >= _kMaxNotes) break;
  }

  return jsonEncode({
    'dark': dark,
    'lang': en ? 'en' : 'tr',
    'streaks': streaks,
    'routines': routineJson,
    'notes': noteJson,
  });
}

/// Anlık görüntüyü native tarafa yollar (widget'lar hemen yeniden çizilir).
Future<void> pushWidgetData(String payload) async {
  try {
    await widgetChannel.invokeMethod<void>('setWidgetData', payload);
  } catch (_) {
    // Kanal yoksa (başka platform) ya da native taraf hazır değilse sessizce
    // geç — widget'lar uygulamanın çalışmasını etkilemez.
  }
}

/// Widget'tan yapılmış rutin işaretlerini veritabanına uygular.
///
/// Kuyruk native tarafta birikir (uygulama kapalıyken de işaretlenebilir);
/// burada alınıp boşaltılır. `setChecked` **kesin durum** yazar, bu yüzden aynı
/// kaydın iki kez işlenmesi zarar vermez.
Future<void> drainPendingRoutineToggles(WidgetRef ref) async {
  String? raw;
  try {
    raw = await widgetChannel.invokeMethod<String>('takePendingRoutineToggles');
  } catch (_) {
    return;
  }
  if (raw == null || raw.isEmpty) return;

  List<dynamic> items;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List || decoded.isEmpty) return;
    items = decoded;
  } catch (_) {
    return;
  }

  final repo = ref.read(routineRepositoryProvider);
  for (final item in items) {
    if (item is! Map) continue;
    final id = item['id'];
    final day = item['day'];
    if (id is! int || day is! String) continue;
    final parsed = DateTime.tryParse(day);
    if (parsed == null) continue;
    await repo.setChecked(
      routineId: id,
      day: parsed,
      done: item['done'] == true,
    );
  }
}

/// Widget verisini canlı tutan sarmalayıcı ([HomeShell]'i sarar).
///
/// - Veri (rutinler, işaretler, belgeler) ya da tema/dil değişince yeni anlık
///   görüntüyü yollar — aynı içerik ise kanalı meşgul etmez.
/// - Uygulama öne geldiğinde widget'tan yapılmış işaretleri alıp uygular.
class WidgetSyncRunner extends ConsumerStatefulWidget {
  const WidgetSyncRunner({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<WidgetSyncRunner> createState() => _WidgetSyncRunnerState();
}

class _WidgetSyncRunnerState extends ConsumerState<WidgetSyncRunner>
    with WidgetsBindingObserver {
  String? _lastPayload;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Açılışta: widget'ta yapılmış işaretleri uygula. Sonrasında veri değişeceği
    // için yeni anlık görüntü zaten build'den gider.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) drainPendingRoutineToggles(ref);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      drainPendingRoutineToggles(ref);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(themeModeProvider);
    final dark = switch (mode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };

    final payload = buildWidgetPayload(ref, dark: dark);
    if (payload != _lastPayload) {
      _lastPayload = payload;
      // build sırasında kanal çağrılmaz.
      WidgetsBinding.instance.addPostFrameCallback((_) => pushWidgetData(payload));
    }
    return widget.child;
  }
}
