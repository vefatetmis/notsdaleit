# notdaleit — Çok Amaçlı Not Uygulaması

Flutter ile geliştirilen çapraz platform bir not + PDF + çizim uygulaması.
Arayüz, Claude Design'dan gelen `design/.../notdaleit.dc.html` tasarımına göre
kodlanmıştır.

## Uzun Vadeli Vizyon

**Hedef platformlar:** Android · iOS · Windows · macOS · Linux · Web
(şu an yalnızca **Android** hedefleniyor; diğerleri `flutter create --platforms=...`
ile eklenecek)

**Nihai özellikler:** not tutma · PDF görüntüleme ve üzerine işaretleme ·
tabletlerde kalemle çizim (kalem/fosforlu/silgi + kalınlık + renk) · cihazlar
arası senkronizasyon.

## Mevcut Durum

Tasarımdaki **tüm ekranlar** kodlandı ve çalışıyor:

- **Kabuk:** geniş ekranda yan panel (daraltılabilir), telefonda çekmece;
  üst bar; ekranlar arası yumuşak geçiş (fade + slide).
- **Kütüphane:** not + PDF kartları (responsive ızgara), "Tümü / Notlar / PDF'ler"
  filtreleri. Not kartlarında tasarıma uygun iskelet çubuk önizleme. **Toplu
  seçim:** karta uzun bas → seçim modu (`librarySelectionProvider`), tap ile
  ekle/çıkar, üstte seçim çubuğu (adet + toplu sil `confirmDeleteDocuments`).
  Geri tuşu önce seçimi temizler. İçe aktar ikonu = ataş (`Icons.attach_file`).
- **Klasörler:** açılır-kapanır klasörler + içindeki dosyalar; "Yeni klasör";
  etiketler (statik).
- **Arama:** başlık/klasör/içerik üzerinde canlı arama.
- **Ayarlar:** tema (açık/koyu) · **dil (Türkçe/English)** · kalem renkleri
  (çubuktaki 3 renk — dokunup paletten seçilir, kalıcı) + kalınlık ·
  senkronizasyon (**temsilî** — yalnızca bilgi mesajı gösterir) · sürüm.
- **Onboarding:** ilk açılışta kısa 4 slaytlı tanıtım (`features/onboarding/`),
  `onboardingDoneProvider` (kalıcı) ile bir kez gösterilir; "Geç" ile atlanır.
- **İki dil (TR/EN):** `core/i18n/i18n.dart` — `localeProvider` (kalıcı) +
  `context.t('Türkçe','English')` uzantısı (ARB/kod üretimi YOK). `MaterialApp.locale`
  buradan gelir; dil Ayarlar'dan seçilir. **Çevrilen ekranlar:** kabuk, kütüphane,
  ayarlar, takvim, onboarding, yeni-not/sil, editör temelleri, boş durumlar.
  **Henüz Türkçe kalan:** klasörler/arama ekranları, bazı araç çubuğu tooltip'leri,
  `date_format` göreli tarihler. Yeni metin eklerken `context.t(tr, en)` kullan.
- **Örnek not tohumlaması KALDIRILDI** — uygulama boş başlar (`seedIfEmpty` no-op).
- **Not editörü (`NoteEditorScreen`):** tüm notlar **boyutlu beyaz sayfa**
  (A4 / Kare). Aynı sayfada hem **biçimli yazı** (flutter_quill) hem **kalemle
  çizim**. Araç çubuğundaki **Aa** ile yazı moduna geçilir (kalın/italik/altı-
  üstü çizili/madde/onay kutusu/font); kalem araçlarıyla çizim moduna. İki
  parmakla yakınlaştırma; en altta yukarı çekip bırakınca yeni sayfa. Metin
  **Quill Delta JSON** olarak `body`'de saklanır (`plainTextFromBody` ile düz
  metne çevrilip önizleme/arama/export'ta kullanılır). Paylaşılan controller:
  `activeQuillControllerProvider` (araç çubuğu okur).
- **Çizim koordinatları genişliğe göre normalize** (`buildScaledPath`,
  `DrawingLayer._norm` — her iki eksen ÷ genişlik) → sayfa yüksekliği metinle
  büyüse bile çizimler kaymaz.
- **Kaydırma/yakınlaştırma (editör):** tek bir **`InteractiveViewer`** ile
  (odak noktalı zoom — dokunulan yere doğru). Kalem modunda tek parmak çizer
  (`panEnabled` parmak sayısına göre: 1=çiz, 2=kaydır/zoom); yazı/el modunda tek
  parmak kaydırır, tap ise Quill'e imleç koyar. Çizim koordinatları artık sayfanın
  kendi (ölçeksiz) uzayında — DrawingLayer `InteractiveViewer` çocuğunun içinde,
  `onPanScroll`/`onPinch` KALDIRILDI. Parmak sayısı editör state'inde `_pointers`
  ile sayılır. Yeni sayfa: sayfa altındaki **"Yeni sayfa"** düğmesi (eski
  yukarı-çek jesti kaldırıldı). Sayfa arası ayrım `_PageLinesPainter`'da hafif
  bir bant ile.
- **Kağıt rengi + yazı rengi:** `editor_state.dart` `kPaperStyles`
  (beyaz/sarı/yeşil/siyah). Yazı rengi **kağıda göre** belirlenir (temadan
  bağımsız → açık/koyu tema değişince yazı okunur kalır; siyah kağıt → beyaz
  yazı). Editör `Theme(paper.isDark? dark: light)` + `_noteStyles` ile metin
  rengini zorlar. Kağıt rengi pen bar'daki palet düğmesinden seçilir
  (`setPageColor`).
- **Yazı boyutu:** text bar'da `_SizeButton` → Quill `size` özniteliği
  (`kFontSizes`).
- **Kalem renkleri:** araç çubuğundaki ilk 3 renk `penPaletteProvider`'dan
  (kalıcı, SharedPreferences 'penPalette'); **Ayarlar → Kalem renkleri**'nden
  dokunup değiştirilir. 4. yuva `_RainbowDot` = "rengarenk" → ortak renk seçici
  (`features/drawing/color_picker.dart`: `kPalette` + `showColorGridDialog`) ile
  her renk; seçilen `customInkColorProvider`'da. Çizim rengi `inkColorFor(palette,
  index, custom)` (index ≥ 3 → custom). Kağıt rengi düğmesi (`_PaperButton`,
  dikey menü) yalnızca **notlarda** görünür (PDF'te sadece çizim).
- **Kaydırma (editör):** `InteractiveViewer` `boundaryMargin: zero` +
  `minScale: 1.0` → varsayılan zoom'da içerik genişliği görünüme eşit olduğundan
  **yatay kilit** (sadece dikey); yalnızca yakınlaştırınca yatay açılır.
- **Menü tutarlılığı:** `app_theme`'de `popupMenuTheme` + `bottomSheetTheme`
  (tüm PopupMenuButton/bottom sheet kart zemini + yuvarlak + kenarlık). Editör
  açılır menüleri (font/boyut/kağıt) ortak anchored-overlay deseninde.
- **Geri tuşu:** `PopScope` ile; detay/alt ekranda uygulamadan çıkmaz, ana
  ekrana döner.
- **Tema kalıcı** (`shared_preferences`), varsayılan **açık**.
- **PDF görüntüleyici:** cihazdan içe aktarılan **gerçek PDF** sayfaları (`pdfx`
  ile render), yakınlaştırma, her sayfanın üstünde çizim katmanı.
- **Çizim:** kalem · fosforlu · silgi · 4 renk · 3 kalınlık · geri al · temizle.
  Çizimler veritabanında kalıcıdır (belge + sayfa bazında).
- **Tema:** Material 3 + tasarımın renk token'ları (açık/koyu), Instrument Sans
  fontu (çevrimdışı için `assets/fonts` içine gömülü).
- Tüm veri cihazda kalıcı (SQLite), internetsiz çalışır.

> **Henüz gerçek olmayan tek şey senkronizasyondur** (tasarımda da temsilî).
> Gerçek bulut senkronu sonraki bir aşamada `data/` katmanına eklenecek.

## DEVAM EDEN — Canlı Ortak Not (Supabase)

**Hedef:** bir notu ikinci bir kişiyle kod üzerinden paylaşmak; çizimler
gerçek zamanlı (append-only stroke olayları), metin debounce'lu tam-gövde
LWW (v1'de eşzamanlı yazmada harf-harf birleşme YOK — bilinçli ödünleşim;
CRDT v2 hedefi). Kimlik: Supabase **anonim oturum** (hesap yok, kod yeter).

**Durum: UYGULANDI — saha testi bekliyor (iki cihaz gerektirir).**
- `supabase_flutter 2.15.4` (Dart 3.7.2 uyumlu). `collab_config.dart` DOLU
  (proje: rubxmneigzzzghmycbcp, klasik JWT **anon key** — publishable key ilk
  denemede 'internet yok' benzeri hata verdi, anon key'e geçildi). Boş
  bırakılırsa özellik tamamen kapanır. Paylaş/katıl hataları
  `collabErrorText` ile teşhisli gösterilir (anonim giriş kapalı / setup.sql
  çalıştırılmamış / anahtar geçersiz / internet yok ayrımı).
- Sunucu: `supabase/setup.sql` kullanıcının projesinde çalıştırıldı varsayımı
  (SETUP-COLLAB.md rehberi). Şema: `shared_notes` + `note_members` +
  `shared_strokes`; RLS (`is_note_member` security definer); RPC:
  `create_shared_note` (6 haneli benzersiz kod) + `join_note`; realtime
  publication. **Anonymous sign-ins açık olmalı.**
- Yerel şema **v7**: `Documents.sharedId`+`shareCode`, `Strokes.remoteId`.
- **`features/collab/collab_service.dart`:** `CollabService.shareNote/joinByCode`
  (RPC'ler; paylaşımda mevcut çizimleri oturum push eder — tek yol).
  **`CollabSession`** (drift ↔ Supabase arasında; UI drift akışlarından
  beslenmeye devam eder): realtime kanal — strokes INSERT (note_id filtreli),
  strokes DELETE (**filtresiz** — DELETE payload'unda yalnız PK var, yerelde
  remoteId ile eşlenir), notes UPDATE (id filtreli, `updated_by == uid` →
  yankı atla). Yerel izleyiciler: strokes fark-diff (remoteId null → push
  [önce sunucu, sonra remoteId yaz — ters sıra offline'da veri kaybettirir],
  kaybolan remoteId → sunucudan sil, `_skipDeletePush` yankı önler); doc watch
  → 600ms debounce push (title/body/pageColor/pageCount, `_last*` snapshot
  fark yoksa atlar). `subscribed` olayında `_initialSync` (LWW gövde + iki
  yönlü stroke farkı) — yeniden bağlanınca kaçanlar tamamlanır.
  `collabSessionProvider` (autoDispose, editör build'de watch) — aktif not
  paylaşımlıysa yaşar; `collabStatusProvider` (canlı/bağlanıyor/çevrimdışı),
  `remoteNoteUpdateProvider` (açık editöre metin uygulama).
- **UI:** üst bar paylaş menüsü → "Canlı paylaş"/"Paylaşım kodu"
  (`collab_ui.dart`: kod diyaloğu + kopyala, katılma diyaloğu 6 haneli kod,
  `CollabStatusChip` üst barda). Ataş menüsü → "Ortak nota katıl". Kütüphane
  kartında paylaşımlı not = kişiler ikonu. Editör: `_applyRemoteUpdate`
  (kullanıcı son 3 sn içinde yazdıysa uygulamaz — LWW; `_applyingRemote`
  bayrağı kaydetme yankısını keser).
- **Bilinen v1 sınırları:** eşzamanlı yazmada harf-harf birleşme yok (LWW);
  geri al "en son çizgiyi" siler (karşı tarafınkini de silebilir); silinen
  yerel not sunucuda kalır (diğer üye kullanmaya devam eder).

## Mimari

Katmanlı + "feature-first". State yönetimi **Riverpod**.

```
lib/
  main.dart                      # seedIfEmpty + ProviderScope + uygulama
  app.dart                       # MaterialApp, tema, themeMode
  core/
    theme/nd_colors.dart         # tasarım renk token'ları (ThemeExtension)
    theme/app_theme.dart         # Material 3 açık/koyu tema + font
    utils/date_format.dart       # göreli Türkçe tarih ("2 sa önce"…)
  data/
    database/database.dart       # drift: Documents + Strokes tabloları (+ .g.dart)
    data_providers.dart          # db, repository'ler, belge akışı, aktif belge
    repositories/
      document_repository.dart   # not + PDF CRUD, ilk açılış seed'i
      drawing_repository.dart    # çizim (stroke) CRUD, geri al / temizle
  features/
    shell/                       # kabuk: yan panel + üst bar + ekran geçişi
      home_shell.dart
      shell_state.dart           # navigasyon, tema, filtre, klasör durumları
      actions.dart               # belge açma / yeni not / PDF içe aktarma / silme
    library/  folders/  search/  settings/   # ana ekranlar
    editor/   pdf/                            # detay ekranları
    drawing/                     # çizim motoru
      drawing_state.dart         # araç / renk / kalınlık / zoom / stroke akışı
      drawing_layer.dart         # dokunuşu yakalayan + çizen overlay
      stroke_painter.dart        # CustomPainter (kalem/fosforlu/silgi)
      drawing_toolbar.dart       # alt yüzen araç çubuğu
    shared/empty_state.dart
```

### Veri modeli (drift)

- **Documents**: `type` ('not'|'pdf'), `title`, `folder`, `body` (not),
  `filePath`+`pageCount` (pdf), `pageSize` ('serbest'|'a4'|'kare', not defteri),
  `pageColor` ('beyaz'|'sari'|'yesil'|'siyah' — kağıt rengi; schemaVersion 5),
  `createdAt`, `updatedAt`. (schemaVersion 2 — pageSize; 5 — pageColor.)
- **Strokes**: `docId` (FK, cascade), `page`, `tool`, `color`, `width`,
  `points` (0..1 normalize edilmiş JSON). Normalize koordinat sayesinde çizimler
  yakınlaştırma/ekran boyutundan bağımsızdır.
- **Tasks** (schemaVersion 3): `title`, `done`, `dueDate`, `remindAt`,
  `createdAt` — takvim/yapılacaklar. Görevde çan ikonu → saat seç → **bildirim
  planlanır** (uzun bas → kaldır). Bildirim id'si = task.id.
- **DayNotes** (schemaVersion 4): `day`, `body` — güne ait serbest not (takvimde
  gün seçince altta yazılır, otomatik kaydeder).
- **Routines + RoutineChecks** (schemaVersion 6): rutin/alışkanlık takibi.
  `Routines.days` = Pzt..Paz için 7 karakterlik '1'/'0' maskesi ('1111111' =
  her gün). `RoutineChecks` = (routineId, day) → o gün yapıldı; işaret kaldırınca
  satır silinir (işaretler böylece her gün "yenilenir"). Ekran:
  `features/routines/routines_screen.dart` — yan panelde **Rutinler** sekmesi;
  "Rutin oluştur" (başlık + haftanın günleri çipleri), bugünün listesi onay
  kutulu, rutine dokununca **geçmiş takvimi** diyaloğu (aylık ızgara: yapıldı =
  dolu vurgu, yapılmadı = halka; geçmiş günlere dokunup düzeltilebilir; aylık
  done/due istatistiği). Uzun bas → sil.
- **Bildirimler:** `core/notifications/notification_service.dart`
  (`flutter_local_notifications` + `timezone` + `flutter_timezone`), main()'de
  init edilir; `exactAllowWhileIdle` ile planlanır. **ÖNEMLİ:** eklenti kendi
  manifestinde alarm alıcılarını TANIMLAMAZ; bu yüzden `AndroidManifest.xml`'e
  `com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver` ve
  `ScheduledNotificationBootReceiver` **elle eklendi** — bunlar olmadan zamanlanan
  bildirimler HİÇ tetiklenmez (eski hata buydu). İzinler: POST_NOTIFICATIONS,
  RECEIVE_BOOT_COMPLETED, VIBRATE, **USE_EXACT_ALARM + SCHEDULE_EXACT_ALARM**
  (kesin alarm; USE_EXACT_ALARM otomatik verilir). `init()` kanalı önceden
  oluşturur; `requestPermission()` bildirim + kesin alarm iznini ister, `bool`
  döner. `showTest()` anında test bildirimi (takvimde "Bildirimi sına"
  düğmesi). app/build.gradle.kts'e **coreLibraryDesugaring** (desugar_jdk_libs
  2.1.4) eklendi. Ekran: `features/calendar/`.

### Neden bu paketler?

- **drift** (+`drift_flutter`,`sqlite3_flutter_libs`): yerel SQLite. Tüm
  platformlarda çalışır, güçlü arama, senkron için sağlam temel.
- **flutter_riverpod**: state yönetimi.
- **pdfx**: gerçek PDF sayfalarını görüntüye render eder (Android'de yerel
  PdfRenderer; ek NDK gerektirmez).
- **file_picker**: cihazdan PDF seçme (v11 API: `FilePicker.pickFiles(...)`).
- **path_provider**: içe aktarılan PDF'i uygulama klasörüne kopyalamak için.
- **shared_preferences**: tema seçimini kalıcı saklamak için.
- **flutter_quill** (+ **flutter_localizations**): sayfa üzerinde zengin metin
  editörü (biçimlendirme + font). Not: `intl` kaldırıldı çünkü flutter_quill'in
  bağımlılığı flutter_localizations `intl 0.19.0`'ı sabitliyor (biz zaten intl'i
  doğrudan kullanmıyorduk). flutter_quill 11.5.0'a sabit (11.5.1+ Dart 3.12 ister).
- **receive_sharing_intent**: PDF'i "Birlikte aç"/paylaş ile notsdaleit'te açma.
  AndroidManifest'te `MainActivity` → `launchMode="singleTask"` + `VIEW`
  (application/pdf, content+file şeması) ve `SEND` intent-filter'ları. Gelen
  dosya `app.dart`'taki `_IncomingPdfHandler` ile yakalanıp `openPdfFromPath`
  ile içe aktarılır. **Build notu:** bu eklenti Kotlin 21 hedefliyor; bu yüzden
  `android/settings.gradle.kts` Kotlin **1.9.25**'e yükseltildi ve
  `android/gradle.properties`'e `kotlin.jvm.target.validation.mode=warning`
  eklendi (Java 1.8 vs Kotlin 21 uyumsuzluğu için).
- **`.ntdl` biçimi (şablon):** `features/ntdl/ntdl_service.dart` — bir notu
  (başlık + sayfa ayarı + metin + çizimler) tek JSON dosyada toplar (format
  marker `'ntdl'`; eski `'nsdl'` de içe aktarılır). Dışa aktar =
  `FilePicker.saveFile` (kullanıcı konum seçer). İçe aktar = `.ntdl` seç → yeni
  not + çizimler. Üst bardaki paylaş/içe-aktar menülerinde. *Not: `share_plus`
  KALDIRILDI (Kotlin 2.2 stdlib'i Kotlin 1.9.25 ile çakışıyordu); yerine
  file_picker saveFile. "Birlikte aç ile .ntdl" **var** (AndroidManifest'te
  `.ntdl` uzantısını pathPattern ile eşleştiren VIEW intent-filter; gelen dosya
  `app.dart`'ta uzantıya bakılıp `importNtdlFromPath` ile içe aktarılır).
  **Şifreleme** henüz yok.*
- **pdf** + **printing**: notu/PDF'i PDF olarak dışa aktarıp paylaşmak için
  (`features/export/pdf_export.dart`). Her sayfa görüntü olarak render edilir;
  metin **Quill Delta'dan biçimli** çizilir (`_parseDelta` + `_paintRichText`:
  kalın/italik/altı-üstü çizili/font boyutu + madde • ve onay kutusu ☐/☑ canvas'a
  çizilir), çizimler üstüne bindirilir. (Eski düz-metin `plainTextFromBody` yolu
  kaldırıldı.)
- **animations**, **intl**: (geçiş yardımcıları / tarih). Çizim animasyonları
  ve ekran geçişleri Flutter'ın kendi widget'larıyla yapılır.

## Sık kullanılan komutlar

```bash
flutter pub get
# Documents/Strokes tablolarını değiştirdikten sonra ÇALIŞTIR:
dart run build_runner build
flutter analyze
# Release APK (çıktı: build/app/outputs/flutter-apk/app-release.apk):
flutter build apk --release
# Play Store için imzalı App Bundle (çıktı: build/app/outputs/bundle/release/app-release.aab):
flutter build appbundle --release
```

### Ekran görüntüsü demosu

Mağaza görselleri için içi dolu, doğal tarihli demo sürüm:
`lib/data/demo_seed.dart` (`seedDemoContent` — yalnızca boş DB'ye tohumlar;
notlar+çizimler+takvim+rutin geçmişi, kademeli tarihlerle). Üretmek için üç
GEÇİCİ değişiklik: main.dart `kSeedDemoContent = true` + gradle
`applicationId = "...notsdaleit.demo"` + manifest label "notsdaleit demo"
→ `flutter build apk --release` → APK'yı `playstore/`a kopyala → üçünü GERİ AL.
Gerçek uygulamanın yanına ikinci uygulama olarak kurulur, veriye dokunmaz.

### Yayın / imzalama

- **applicationId:** `com.bronzecloud.notsdaleit`. **Sürüm:** pubspec `version`
  (`1.0.0+1` → versionName 1.0.0, versionCode 1). Her Play yüklemesinde
  **versionCode artırılmalı** (pubspec `+2`, `+3`…).
- **İmza:** `android/upload-keystore.jks` (alias `upload`), şifreler
  `android/key.properties`'te. `app/build.gradle.kts` bu dosyayı okuyup release'i
  imzalar; `key.properties` yoksa debug'a düşer. **Bu iki dosya gizli + kritik:**
  yedeklenmeli, kaybedilirse Play'de yükleme anahtarı sıfırlaması gerekir. (Play
  App Signing kullanılırsa uygulama imza anahtarını Google tutar.)

## Önemli notlar / gelecek oturumlar için

- **Sürüm sabitleri:** Dart SDK 3.7.2 kullanıldığı için `flutter_riverpod` 2.6.x,
  `drift`/`drift_dev` 2.30.x'e sabitlendi (yeni sürümler Dart 3.10 istiyor).
  Android `ndkVersion` = 27.0.12077973 (eklentiler istiyor).
- **Senkronizasyon:** Ayarlar'daki "Bağlan" şu an sadece mesaj gösterir. Gerçek
  senkron `data/` katmanına (repository arkasına) eklenmelidir.
- **Klasör/etiket:** klasörler belgelerin `folder` alanından türetilir; "Yeni
  klasör" oturumluk (kalıcı değil). Etiketler statik. Kalıcı klasör/etiket için
  ayrı tablolar gerekir.
- **Şema değişirse** `schemaVersion` artır + migration yaz, sonra build_runner.
- **Yeni platform:** `flutter create --platforms=ios,windows,macos,linux,web .`
  (web'de drift için WASM, pdfx için pdf.js kurulumu gerekir).
- **PLANLANAN — birleşik zengin-metin editörü:** hedef, tüm notların boyutlu
  sayfa olması; her sayfada hem kalemle çizim hem **biçimli metin** (kalın/
  italik/altı-üstü çizili, madde ve **onay kutulu liste**), araç çubuğunda
  **Aa/klavye** ile çizim ↔ metin modu geçişi, font seçimi. Muhtemel yol
  `flutter_quill` (önce Dart 3.7.2 uyumu doğrulanmalı). Bu, `NoteEditorScreen`
  ve `NotebookEditorScreen`'i tek bir editörde birleştirecek.
- **Şablon paylaşımı / mağaza** (uzak gelecek): kullanıcıların şablon paylaştığı
  arayüz — backend/senkron gerektirir; şimdilik yalnızca PDF dışa aktarma var.
```
