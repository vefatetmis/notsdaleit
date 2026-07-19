import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Yerel bildirimler (görev hatırlatıcıları). Basit ve savunmacı: hata olursa
/// sessizce geçer, uygulamayı bozmaz.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _channel = AndroidNotificationChannel(
    'reminders',
    'Hatırlatıcılar',
    description: 'Görev hatırlatıcıları',
    importance: Importance.max,
  );

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'Hatırlatıcılar',
      channelDescription: 'Görev hatırlatıcıları',
      importance: Importance.max,
      priority: Priority.high,
    ),
  );

  /// Kesin alarm izni varsa tam zamanında, yoksa yaklaşık zamanlı planla.
  Future<AndroidScheduleMode> _pickMode() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (await android?.canScheduleExactNotifications() ?? false) {
        return AndroidScheduleMode.exactAllowWhileIdle;
      }
    } catch (_) {}
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {}
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    try {
      await _plugin.initialize(settings);
      // Bildirim kanalını önceden oluştur (Android 8+); planlamadan bağımsız.
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
      _ready = true;
    } catch (_) {}
  }

  /// Bildirim iznini ister (Android 13+). İzin verildiyse true döner.
  Future<bool> requestPermission() async {
    if (!_ready) await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    try {
      final granted = await android?.requestNotificationsPermission();
      // Bazı OEM'lerde kesin alarm izni de gerekebilir; sessizce iste.
      await android?.requestExactAlarmsPermission();
      return granted ?? true;
    } catch (_) {
      return false;
    }
  }

  /// Anında bir test bildirimi gösterir (kullanıcı "çalışıyor mu?" görebilsin).
  Future<void> showTest() async {
    if (!_ready) await init();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'reminders',
        'Hatırlatıcılar',
        channelDescription: 'Görev hatırlatıcıları',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );
    try {
      await _plugin.show(
        999000,
        'Bildirimler açık',
        'Hatırlatıcılar bu şekilde görünecek.',
        details,
      );
    } catch (_) {}
  }

  Future<void> schedule({
    required int id,
    required String title,
    required DateTime when,
  }) async {
    if (!_ready) await init();
    if (!_ready) return;
    if (when.isBefore(DateTime.now())) return;
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        'notsdaleit hatırlatıcı',
        tz.TZDateTime.from(when, tz.local),
        _details,
        androidScheduleMode: await _pickMode(),
      );
    } catch (_) {}
  }

  /// Bir rutin için seçili hafta günlerinde, verilen dakikada HAFTALIK tekrar
  /// eden bildirim planlar. [days] Pzt..Paz için '1'/'0' maskesi.
  Future<void> scheduleRoutine({
    required int routineId,
    required String title,
    required String body,
    required String days,
    required int minuteOfDay,
  }) async {
    await cancelRoutine(routineId);
    if (!_ready) await init();
    if (!_ready) return;
    final mode = await _pickMode();
    final hour = minuteOfDay ~/ 60;
    final minute = minuteOfDay % 60;
    for (var wd = 1; wd <= 7; wd++) {
      if (days.length < wd || days[wd - 1] != '1') continue;
      try {
        await _plugin.zonedSchedule(
          _routineNotifId(routineId, wd),
          title,
          body,
          _nextWeekdayTime(wd, hour, minute),
          _details,
          androidScheduleMode: mode,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      } catch (_) {}
    }
  }

  Future<void> cancelRoutine(int routineId) async {
    for (var wd = 1; wd <= 7; wd++) {
      await cancel(_routineNotifId(routineId, wd));
    }
  }

  // Görev id'leriyle (küçük int) çakışmayan rutin bildirim id'si.
  static int _routineNotifId(int routineId, int weekday) =>
      100000 + routineId * 10 + weekday;

  tz.TZDateTime _nextWeekdayTime(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var d = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (d.weekday != weekday || !d.isAfter(now)) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }

  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }
}
