/// Canlı ortak not (Supabase) yapılandırması.
///
/// Değerler boşken özellik tamamen KAPALIDIR: uygulama Supabase'e hiç
/// bağlanmaz, paylaşım menüleri gizlenir. Supabase projesi kurulunca
/// (bkz. SETUP-COLLAB.md) iki sabit doldurulur ve özellik açılır.
class CollabConfig {
  const CollabConfig._();

  /// Supabase proje adresi (Dashboard → Settings → API → Project URL).
  /// Örn: 'https://abcdefghijklm.supabase.co'
  static const String url = 'https://rubxmneigzzzghmycbcp.supabase.co';

  /// Supabase genel istemci anahtarı. İki biçimden HERHANGİ BİRİ olabilir:
  /// - eski "anon key" (eyJ... ile başlar)
  /// - yeni "publishable key" (sb_publishable_... ile başlar)
  /// (Dashboard → Settings → API / API Keys.) İstemciye gömülmek için
  /// tasarlanmıştır; veri erişimi satır seviyesi güvenlik (RLS) ile korunur.
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1YnhtbmVpZ3p6emdobXljYmNwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQxMDczNjEsImV4cCI6MjA5OTY4MzM2MX0.bR__FTyFG8bExHqE7eIyMOHPVEH5hq76gGzkPv7fp4g';

  /// Yeni tür anahtar mı? (Supabase.initialize'da doğru parametreyi seçer.)
  static bool get isPublishableKey => anonKey.startsWith('sb_publishable_');

  static bool get enabled => url.isNotEmpty && anonKey.isNotEmpty;
}
