import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shell/shell_state.dart';

/// Rutin serisi (streak) ve rozet hesapları. Durum SAKLANMAZ; tamamlama
/// kayıtlarından (RoutineChecks) türetilir.

const List<int> kBadgeThresholds = [3, 7, 14, 30, 100];

bool _sched(String mask, int weekdayIndex) =>
    weekdayIndex >= 0 && weekdayIndex < mask.length && mask[weekdayIndex] == '1';

DateTime _prev(DateTime d) => DateTime(d.year, d.month, d.day - 1);
DateTime _next(DateTime d) => DateTime(d.year, d.month, d.day + 1);
bool _same(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Bugünden geriye, planlı günlerde kesintisiz "yapıldı" serisi. Bugün planlı
/// ama henüz yapılmadıysa seriyi BOZMAZ (dünden sayar). Planlı olmayan gün
/// atlanır (seriyi ne bozar ne uzatır). [today] ve [created] gün başı (00:00).
int currentStreak(
    String days, Set<DateTime> checked, DateTime today, DateTime created) {
  var streak = 0;
  var d = today;
  var guard = 0;
  while (!d.isBefore(created) && guard++ < 4000) {
    if (_sched(days, d.weekday - 1)) {
      if (checked.contains(d)) {
        streak++;
      } else if (_same(d, today)) {
        // bugün henüz yapılmadı → grace, seriyi kırma
      } else {
        break;
      }
    }
    d = _prev(d);
  }
  return streak;
}

/// Geçmişteki en uzun kesintisiz seri (rozetler bundan hesaplanır).
int longestStreak(
    String days, Set<DateTime> checked, DateTime today, DateTime created) {
  var best = 0;
  var run = 0;
  var d = created;
  var guard = 0;
  while (!d.isAfter(today) && guard++ < 4000) {
    if (_sched(days, d.weekday - 1)) {
      if (checked.contains(d)) {
        run++;
        if (run > best) best = run;
      } else if (!_same(d, today)) {
        run = 0;
      }
    }
    d = _next(d);
  }
  return best;
}

/// [longest]'e göre kazanılan en yüksek rozet eşiği (yoksa 0).
int earnedBadge(int longest) {
  var b = 0;
  for (final t in kBadgeThresholds) {
    if (longest >= t) b = t;
  }
  return b;
}

/// Seri ve rozetler gösterilsin mi? (kalıcı, varsayılan AÇIK)
class StreaksEnabledNotifier extends Notifier<bool> {
  static const _key = 'streaksEnabled';

  @override
  bool build() => ref.read(sharedPrefsProvider).getBool(_key) ?? true;

  void set(bool value) {
    state = value;
    ref.read(sharedPrefsProvider).setBool(_key, value);
  }
}

final streaksEnabledProvider =
    NotifierProvider<StreaksEnabledNotifier, bool>(StreaksEnabledNotifier.new);
