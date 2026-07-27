import 'package:flutter/widgets.dart';

import '../i18n/i18n.dart';

/// Göreli, kısa zaman biçimi ("şimdi", "2 sa önce", "dün", "1 hf önce" …).
/// Locale kurulumu (intl) gerektirmez; dil `context.isEn` üzerinden seçilir.
String formatRelativeIn(DateTime dateTime, {required bool en}) {
  final diff = DateTime.now().difference(dateTime);

  if (diff.inSeconds < 60) return en ? 'now' : 'şimdi';
  if (diff.inMinutes < 60) {
    return en ? '${diff.inMinutes}m ago' : '${diff.inMinutes} dk önce';
  }
  if (diff.inHours < 24) {
    return en ? '${diff.inHours}h ago' : '${diff.inHours} sa önce';
  }

  final days = diff.inDays;
  if (days == 1) return en ? 'yesterday' : 'dün';
  if (days < 7) return en ? '${days}d ago' : '$days gün önce';
  if (days < 30) {
    final w = (days / 7).floor();
    return en ? '${w}w ago' : '$w hf önce';
  }
  if (days < 365) {
    final m = (days / 30).floor();
    return en ? '${m}mo ago' : '$m ay önce';
  }
  final y = (days / 365).floor();
  return en ? '${y}y ago' : '$y yıl önce';
}

/// Ekranlarda kullanılan kısayol — dili context'ten alır.
String formatRelative(BuildContext context, DateTime dateTime) =>
    formatRelativeIn(dateTime, en: context.isEn);

/// **Kısaltılmış** göreli zaman: "9 dk", "2 sa", "1 g", "3 hf".
///
/// "önce"/"ago" eki yok — ana ekran widget'ının 2×2 ızgarasında satır
/// "klasör · zaman" olarak yazılıyor ve tasarım (Widgetlar.dc.html) orada bu
/// kısa biçimi kullanıyor; uzun biçim kartı taşırıyordu.
String formatRelativeShortIn(DateTime dateTime, {required bool en}) {
  final diff = DateTime.now().difference(dateTime);

  if (diff.inSeconds < 60) return en ? 'now' : 'şimdi';
  if (diff.inMinutes < 60) return en ? '${diff.inMinutes}m' : '${diff.inMinutes} dk';
  if (diff.inHours < 24) return en ? '${diff.inHours}h' : '${diff.inHours} sa';

  final days = diff.inDays;
  if (days < 7) return en ? '${days}d' : '$days g';
  if (days < 30) return en ? '${(days / 7).floor()}w' : '${(days / 7).floor()} hf';
  if (days < 365) return en ? '${(days / 30).floor()}mo' : '${(days / 30).floor()} ay';
  return en ? '${(days / 365).floor()}y' : '${(days / 365).floor()} y';
}
