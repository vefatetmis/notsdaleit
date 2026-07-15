/// Tasarımdaki göreli, Türkçe zaman biçimi ("şimdi", "2 sa önce", "dün",
/// "1 hf önce" …). Locale kurulumu gerektirmez.
String formatRelative(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);

  if (diff.inSeconds < 60) return 'şimdi';
  if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
  if (diff.inHours < 24) return '${diff.inHours} sa önce';

  final days = diff.inDays;
  if (days == 1) return 'dün';
  if (days < 7) return '$days gün önce';
  if (days < 30) return '${(days / 7).floor()} hf önce';
  if (days < 365) return '${(days / 30).floor()} ay önce';
  return '${(days / 365).floor()} yıl önce';
}
