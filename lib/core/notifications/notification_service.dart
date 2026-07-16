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

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'reminders',
        'Hatırlatıcılar',
        channelDescription: 'Görev hatırlatıcıları',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );
    // Kesin alarm izni verildiyse tam zamanında; verilmediyse yaklaşık
    // zamanlı planla (birkaç dakika sapabilir ama bildirim mutlaka gelir).
    var mode = AndroidScheduleMode.inexactAllowWhileIdle;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (await android?.canScheduleExactNotifications() ?? false) {
        mode = AndroidScheduleMode.exactAllowWhileIdle;
      }
    } catch (_) {}
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        'notsdaleit hatırlatıcı',
        tz.TZDateTime.from(when, tz.local),
        details,
        androidScheduleMode: mode,
      );
    } catch (_) {}
  }

  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }
}
