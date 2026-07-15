import 'package:flutter_test/flutter_test.dart';
import 'package:notsdaleit/core/utils/date_format.dart';

void main() {
  group('formatRelative', () {
    test('bir dakikadan yeni ise "şimdi"', () {
      expect(formatRelative(DateTime.now()), 'şimdi');
    });

    test('saatler için "sa önce"', () {
      final t = DateTime.now().subtract(const Duration(hours: 3));
      expect(formatRelative(t), '3 sa önce');
    });

    test('bir gün önce için "dün"', () {
      final t = DateTime.now().subtract(const Duration(days: 1, hours: 1));
      expect(formatRelative(t), 'dün');
    });

    test('bir hafta için "hf önce"', () {
      final t = DateTime.now().subtract(const Duration(days: 9));
      expect(formatRelative(t), '1 hf önce');
    });
  });
}
