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

## 2) E-posta ŞABLONUNA 6 haneli kodu ekle (BURASI ŞART)

**Sorun:** Supabase'in varsayılan e-postası **link** gönderir (tıklayınca
localhost:3000 açılır). Biz **6 haneli kod** istiyoruz. Çözüm: şablonların
gövdesine kodu basan `{{ .Token }}` değişkenini koymak.

Dashboard → **Authentication → Emails → Templates**. Şu **ÜÇ** şablonu düzenle
(hangisinin geleceği duruma göre değişir, üçünü de yapmak en garantisi):

| Şablon | Ne zaman gelir |
|--------|----------------|
| **Confirm signup** | İlk kez giriş yapan **yeni** e-posta |
| **Magic Link** | Daha önce giriş yapmış e-posta |
| **Change Email Address** | Collab için anonim oturumu olan kullanıcı hesaba yükseltilirken |

Her birinin gövdesini (HTML) şununla değiştir — **link YOK, sadece kod**:

```html
<h2>Giriş kodun</h2>
<p style="font-size:28px;font-weight:bold;letter-spacing:4px">{{ .Token }}</p>
<p>Bu kodu uygulamaya gir. Kod 1 saat geçerlidir. Sen istemediysen bu
e-postayı yok say.</p>
```

Kaydet. Artık e-postada tıklanacak link değil, **6 haneli kod** gelir.

## 3) localhost:3000 sorunu (Site URL)

Link'e basınca localhost:3000 açılmasının sebebi: **Authentication → URL
Configuration → Site URL** varsayılan `http://localhost:3000`. Yukarıdaki adımı
yapınca artık **link göndermeyeceğiz** (sadece kod), dolayısıyla bu sorun
kendiliğinden biter. İstersen Site URL'i boş bırakmak yerine geçici bir değere
(örn. `https://notsdaleit.app`) çekebilirsin — kod akışı için şart değil.

## 4) (Öneri) Kod ayarları

Authentication → **Providers → Email** (veya Emails → Settings):
- **Email OTP Expiration**: 3600 sn (1 saat) yeter.
- **Email OTP Length**: 6.

## Bu kadar

Ayarları yapınca uygulamada: **Ayarlar → Hesap & senkronizasyon → Giriş yap**
ya da ilk açılıştaki tanıtımın sonundaki **Giriş yap / Kaydol**. E-posta gir →
gelen 6 haneli kodu yaz → (ilk kez) görünen adını gir. Bitti.

> **Not (Faz 1 kapsamı):** Bu adım hesap + profil (görünen ad) getirir. Görünen
> ad şimdilik Supabase **kullanıcı metadata**'sında saklanır — ayrı bir tablo
> gerekmez. Başkalarının ortak notta adını görmesi (Faz 2) ve notların
> cihazlar arası gerçek senkronu (Faz 3) sonraki adımlarda; onlar için ek SQL
> verilecek.
