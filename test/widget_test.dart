import 'package:flutter_test/flutter_test.dart';
import 'package:notsdaleit/core/utils/date_format.dart';

void main() {
  group('formatRelativeIn (tr)', () {
    test('bir dakikadan yeni ise "şimdi"', () {
      expect(formatRelativeIn(DateTime.now(), en: false), 'şimdi');
    });

    test('saatler için "sa önce"', () {
      final t = DateTime.now().subtract(const Duration(hours: 3));
      expect(formatRelativeIn(t, en: false), '3 sa önce');
    });

    test('bir gün önce için "dün"', () {
      final t = DateTime.now().subtract(const Duration(days: 1, hours: 1));
      expect(formatRelativeIn(t, en: false), 'dün');
    });

    test('bir hafta için "hf önce"', () {
      final t = DateTime.now().subtract(const Duration(days: 9));
      expect(formatRelativeIn(t, en: false), '1 hf önce');
    });
  });

  group('formatRelativeIn (en)', () {
    test('now', () {
      expect(formatRelativeIn(DateTime.now(), en: true), 'now');
    });

    test('hours', () {
      final t = DateTime.now().subtract(const Duration(hours: 3));
      expect(formatRelativeIn(t, en: true), '3h ago');
    });

    test('yesterday', () {
      final t = DateTime.now().subtract(const Duration(days: 1, hours: 1));
      expect(formatRelativeIn(t, en: true), 'yesterday');
    });

    test('weeks', () {
      final t = DateTime.now().subtract(const Duration(days: 9));
      expect(formatRelativeIn(t, en: true), '1w ago');
    });
  });

  // Ana ekran widget'ının 2×2 ızgarası "Kişisel · 17 sa" gibi kısa biçim
  // kullanıyor (tasarım kararı); uzun biçim kartı taşırıyordu.
  group('formatRelativeShortIn', () {
    test('saatler "önce" eki almaz (tr)', () {
      final t = DateTime.now().subtract(const Duration(hours: 17));
      expect(formatRelativeShortIn(t, en: false), '17 sa');
    });

    test('dakikalar (tr)', () {
      final t = DateTime.now().subtract(const Duration(minutes: 9));
      expect(formatRelativeShortIn(t, en: false), '9 dk');
    });

    test('günler "dün" değil sayı verir (tr)', () {
      final t = DateTime.now().subtract(const Duration(days: 1, hours: 1));
      expect(formatRelativeShortIn(t, en: false), '1 g');
    });

    test('hours (en)', () {
      final t = DateTime.now().subtract(const Duration(hours: 2));
      expect(formatRelativeShortIn(t, en: true), '2h');
    });
  });
}
