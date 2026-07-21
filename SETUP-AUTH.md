# E-posta ile giriş (Faz 1) — Supabase kurulumu

Uygulamaya **e-posta ile giriş** (parolasız, 6 haneli kod) eklendi. Kod tamamen
hazır; çalışması için Supabase panelinde **iki küçük ayar** yapman yeterli.
(Aynı proje collab için de kullanılıyor — `SETUP-COLLAB.md`.)

## 1) E-posta girişini aç (çoğunlukla zaten açık)

Supabase Dashboard → **Authentication → Sign In / Providers → Email**:

- **Email** sağlayıcısı **açık** olmalı.
- "Confirm email" açık kalabilir (OTP akışında sorun olmaz).
- **Anonymous sign-ins** açık kalsın (collab için gerekiyordu; giriş bunu
  kalıcı hesaba yükseltir).

## 2) E-posta ŞABLONUNA 6 haneli kodu ekle (ÖNEMLİ)

Varsayılan Supabase e-postaları **link** gönderir; biz **6 haneli kod**
istiyoruz. Dashboard → **Authentication → Emails → Templates**:

- **"Magic Link"** ve **"Change Email Address"** şablonlarını aç.
- İçine kodu basan `{{ .Token }}` değişkenini ekle. Örn. gövdeye şu satırı
  koy:

  ```html
  <p>Giriş kodun: <strong>{{ .Token }}</strong></p>
  <p>Bu kod 1 saat geçerlidir.</p>
  ```

  (İstersen linki de bırakabilirsin; uygulama kodu kullanıyor.)

Neden iki şablon? Yeni kullanıcı **Magic Link** şablonuyla, daha önce collab
için anonim oturum açmış kullanıcı ise hesabını yükseltirken **Change Email
Address** şablonuyla kod alır.

## 3) (Öneri) Kod ayarları

Authentication → **Emails → Settings** (veya Providers → Email):
- **OTP expiry**: 3600 sn (1 saat) yeter.
- **OTP length**: 6.

## Bu kadar

Ayarları yapınca uygulamada: **Ayarlar → Hesap & senkronizasyon → Giriş yap**
ya da ilk açılıştaki tanıtımın sonundaki **Giriş yap / Kaydol**. E-posta gir →
gelen 6 haneli kodu yaz → (ilk kez) görünen adını gir. Bitti.

> **Not (Faz 1 kapsamı):** Bu adım hesap + profil (görünen ad) getirir. Görünen
> ad şimdilik Supabase **kullanıcı metadata**'sında saklanır — ayrı bir tablo
> gerekmez. Başkalarının ortak notta adını görmesi (Faz 2) ve notların
> cihazlar arası gerçek senkronu (Faz 3) sonraki adımlarda; onlar için ek SQL
> verilecek.
