import 'dart:convert';

/// Not gövdesi (Quill Delta JSON veya eski düz metin) → düz metin.
/// Kütüphane önizlemesi, arama ve PDF dışa aktarma için kullanılır.
String plainTextFromBody(String body) {
  if (body.trim().isEmpty) return '';
  try {
    final data = jsonDecode(body);
    if (data is List) {
      final sb = StringBuffer();
      for (final op in data) {
        if (op is Map && op['insert'] is String) {
          sb.write(op['insert']);
        }
      }
      return sb.toString().trim();
    }
  } catch (_) {
    // Eski düz metin notu.
  }
  return body.trim();
}
