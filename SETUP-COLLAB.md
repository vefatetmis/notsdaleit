# Canlı Ortak Not — Supabase Kurulumu (bir kez, ~10 dakika)

Bu adımları yalnızca **siz** yapabilirsiniz (hesap açmak gerekiyor).
Bittiğinde bana **2 değer** vereceksiniz, gerisini ben bağlayacağım.

## 1. Hesap ve proje

1. Tarayıcıda **https://supabase.com** → **Start your project** → GitHub veya
   e-posta ile ücretsiz kayıt olun.
2. **New project** deyin:
   - **Name:** `notsdaleit`
   - **Database password:** güçlü bir şifre yazın ve **bir yere not edin**
     (günlük kullanımda gerekmeyecek ama kaybolmasın).
   - **Region:** `Frankfurt (eu-central-1)` seçin (Türkiye'ye en yakın).
   - **Create new project** → 1-2 dakika kurulmasını bekleyin.

## 2. Veritabanını kur (kopyala-yapıştır)

1. Sol menüden **SQL Editor**'ü açın.
2. Proje klasöründeki **`supabase/setup.sql`** dosyasının TÜM içeriğini
   kopyalayıp editöre yapıştırın.
3. Sağ alttaki **Run** düğmesine basın. "Success" görmelisiniz.
   - "already member of publication" benzeri bir hata görürseniz sorun değil
     (betik ikinci kez çalıştırılmıştır) — devam edin.

## 3. Anonim girişi aç

1. Sol menü → **Authentication** → **Sign In / Providers** (veya Settings).
2. **Anonymous sign-ins** anahtarını **açın** (Enable).
   - Bu sayede kullanıcılar hesap/şifre olmadan paylaşım yapabilir; veriye
     erişim yine satır-seviyesi güvenlikle (RLS) korunur.

## 4. İki değeri bana ver

1. Sol menü → **Settings** (dişli) → **API** (veya **API Keys**).
2. Şu ikisini kopyalayıp bana mesajla gönderin:
   - **Project URL** — `https://xxxx.supabase.co` biçiminde
   - Genel istemci anahtarı — panelde hangisi görünüyorsa:
     **anon / public key** (`eyJ...` ile başlar) **veya**
     **publishable key** (`sb_publishable_...` ile başlar)
     (⚠️ `service_role` / `secret` anahtarını DEĞİL — o gizli kalmalı!)

> anon anahtarı uygulamaya gömülmek için tasarlanmıştır, paylaşması güvenlidir.
> Veriler RLS kurallarıyla korunur: bir nota yalnızca üyeleri erişebilir.

## 5. Sonrası (ben yapacağım)

- İki değeri `lib/core/collab/collab_config.dart` içine koyacağım.
- Paylaşım arayüzünü bağlayıp yeni APK üreteceğim.
- Test: iki telefona kurup birinde "Canlı paylaş" → koda diğer telefonda
  "Katıl" → çizimin anlık aktığını göreceğiz.
