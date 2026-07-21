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
  `filePath`+`pageCount` (pdf), `pageSize` ('serbest'|'a4'|'yatay'|'kare'|
  'telefon', not defteri — aspect `aspectForPageSize`), `pageColor`
  ('beyaz'|'sari'|'yesil'|'siyah' — kağıt rengi; schemaVersion 5),
  `pageBackground` ('duz'|'cizgili'|'kareli'|'noktali' — sayfa deseni;
  schemaVersion 10), `createdAt`, `updatedAt`. (schemaVersion 2 — pageSize;
  5 — pageColor; 10 — pageBackground.)
- **Templates** (schemaVersion 9; `pageBackground` schemaVersion 10): `title`,
  `pageSize`, `pageColor`, `pageBackground`, `body` (Delta JSON), `strokes`
  (JSON dizisi), `createdAt` — kullanıcının kaydettiği not şablonları
  ("Şablonlarım"). Gömülü hazır şablonlar koddadır
  (`features/templates/templates_data.dart`). Bkz. Sürüm 1.2 bölümü.
- **Strokes**: `docId` (FK, cascade), `page`, `tool`, `color`, `width`,
  `points` (0..1 normalize edilmiş JSON). Normalize koordinat sayesinde çizimler
  yakınlaştırma/ekran boyutundan bağımsızdır.
- **Tasks** (schemaVersion 3): `title`, `done`, `dueDate`, `remindAt`,
  `createdAt` — takvim/yapılacaklar. Görevde çan ikonu → saat seç → **bildirim
  planlanır** (uzun bas → kaldır). Bildirim id'si = task.id.
- **DayNotes** (schemaVersion 4): `day`, `body` — güne ait serbest not (takvimde
  gün seçince altta yazılır, otomatik kaydeder).
- **Routines + RoutineChecks** (schemaVersion 6; `remindAt` schemaVersion 8):
  rutin/alışkanlık takibi. `Routines.days` = Pzt..Paz için 7 karakterlik '1'/'0'
  maskesi ('1111111' = her gün). `Routines.remindAt` = gece yarısından dakika
  (nullable) → seçili günlerde haftalık bildirim (`scheduleRoutine`, id =
  100000+routineId*10+weekday). `RoutineChecks` = (routineId, day) → o gün
  yapıldı; işaret kaldırınca satır silinir. **Seri/rozet** (`streaks.dart`):
  RoutineChecks'ten türetilir (durum saklanmaz); eşik 3/7/14/30/100; Ayarlar'da
  `streaksEnabledProvider` ile aç/kapa.
- **Folders** (schemaVersion 8): kalıcı klasörler (boş klasör yaşasın).
  `folderNamesProvider` = varsayılanlar ∪ tablo ∪ belge klasörleri. Kütüphane
  çoklu seçim çubuğunda "Klasöre taşı" (`move_to_folder.dart`). Ekran:
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
- Çizim animasyonları ve ekran geçişleri Flutter'ın kendi widget'larıyla
  yapılır (`animations` paketi kullanılmıyordu, kaldırıldı; `intl` de daha
  önce kaldırılmıştı).

## Sık kullanılan komutlar

> **İKİ FLAVOR (prod/dev) → her build/run'a `--flavor` ZORUNLU.** Flavor'sız
> `flutter build apk` artık hata verir. Ayrıntı: aşağıdaki "Paralel (dev) APK".

```bash
flutter pub get
# Documents/Strokes tablolarını değiştirdikten sonra ÇALIŞTIR:
dart run build_runner build
flutter analyze

# ── PARALEL (dev) SÜRÜM — günlük geliştirme/test buradan ──
# Kurulabilir dev APK (çıktı: build/app/outputs/flutter-apk/app-dev-release.apk):
flutter build apk --release --flavor dev
# Cihaza takıp çalıştırma / sıcak yeniden yükleme:
flutter run --flavor dev

# ── PROD SÜRÜM — sadece Play'e yükleme anında ──
# Release APK (çıktı: build/app/outputs/flutter-apk/app-prod-release.apk):
flutter build apk --release --flavor prod
# Play için imzalı App Bundle
# (çıktı: build/app/outputs/bundle/prodRelease/app-prod-release.aab):
flutter build appbundle --release --flavor prod
```

### Paralel (dev) APK — geliştirme akışı

Play kanalı (kapalı test / üretim) ve günlük geliştirme birbirini bozmasın diye
**iki Android flavor** var (`app/build.gradle.kts`, `flavorDimensions "track"`):

- **prod** → applicationId `com.bronzecloud.notsdaleit` (bugünküyle **birebir
  aynı**; Play'e giden tek sürüm). Manifest/etiket `src/main`'den.
- **dev** → applicationId `com.bronzecloud.notsdaleit.dev`, versionName sonuna
  `-dev`, launcher adı **"notdaleit dev"** (`src/dev/AndroidManifest.xml` sadece
  `android:label`'ı override eder). Farklı applicationId sayesinde gerçek
  uygulamanın **yanına** kurulur, üstüne yazmaz; Play'e **asla** yüklenmez.
  Eklenti FileProvider'ları `${applicationId}` kullandığından dev sağlayıcıları
  otomatik `...dev.*` olur → prod ile çakışmaz.

**İş akışı (kullanıcı kararı):** bundan sonraki tüm geliştirme **dev APK**
üzerinden yapılır; biriktirilen özellikler kapalı testten geçince **prod** AAB
tek seferde yayınlanır. Yani prod'a dokunmadan istediğin kadar dev sürüm
denenir. Yeni sürümü kullanıcıya verirken: `flutter build apk --release
--flavor dev` → `build/app/outputs/flutter-apk/app-dev-release.apk`.

### Ekran görüntüsü demosu (KALDIRILDI — gerekirse geri getirilebilir)

Mağaza görselleri alındıktan sonra demo tohumlayıcı silindi. Yeniden gerekirse
`lib/data/demo_seed.dart` + main.dart `kSeedDemoContent` bayrağı git geçmişinde
**3ef8868 / 3bf1a51** commit'lerinde duruyor (`git show 3bf1a51:lib/data/demo_seed.dart`).
Kullanımı: bayrak true + gradle applicationId'ye ".demo" eki + manifest label
"notsdaleit demo" → release APK → üç geçici değişikliği geri al.

### Yayın / imzalama

- **applicationId:** `com.bronzecloud.notsdaleit` (yalnızca **prod** flavor;
  dev flavor `.dev` ekiyle ayrı kurulur, Play'e gitmez). **Sürüm:** pubspec
  `version` (`1.0.0+1` → versionName 1.0.0, versionCode 1). Her Play
  yüklemesinde **versionCode artırılmalı** (pubspec `+2`, `+3`…).
- **Play'e yüklenecek AAB:** her zaman `flutter build appbundle --release
  --flavor prod` (flavor'sız komut artık çalışmaz).
- **İmza:** `android/upload-keystore.jks` (alias `upload`), şifreler
  `android/key.properties`'te. `app/build.gradle.kts` bu dosyayı okuyup release'i
  imzalar; `key.properties` yoksa debug'a düşer. **Bu iki dosya gizli + kritik:**
  yedeklenmeli, kaybedilirse Play'de yükleme anahtarı sıfırlaması gerekir. (Play
  App Signing kullanılırsa uygulama imza anahtarını Google tutar.)

## Sürüm 1.1 — UYGULANDI (yayın bekliyor, pubspec 1.1.0+3)

Kod hazır ve derleniyor; kapalı test bitip üretim onayı gelince AAB yüklenecek
(mağazada hâlâ 1.0). Şema **v8** (Routines.remindAt + Folders tablosu).
Yapılanlar:

1. **Varsayılan mod yazı:** not açılınca `toolProvider = PenTool.yazi`
   (PDF'te değişmez, `_resetTools` ayrışacak). Boş notta Quill autofocus
   (klavye direkt gelsin); dolu notta dokununca. "Yazmaya başlayın…" tıklaması
   klavyeyi açmalı.
2. **Canlı paylaşımı durdurma:** paylaş menüsü → sahipse "Paylaşımı durdur"
   (sunucuda shared_notes DELETE — RLS'te created_by kuralı VAR; yerelde
   sharedId/shareCode NULL), üyeyse "Paylaşımdan ayrıl" (note_members kendi
   satırını siler — RLS kuralı VAR; yerel kopya kişisel nota döner).
   CollabSession: initial sync'te not 404/silinmişse sharedId'yi yerelde
   temizle + tek seferlik "paylaşım sonlandırıldı" bildir. setup.sql'e ek
   gerekirse kullanıcıya tek seferlik SQL verilecek.
3. **Klasöre taşıma:** kütüphane çoklu seçim çubuğuna + not menüsüne
   "Klasöre taşı" (mevcut `updateFolder` repo metodu hazır). Klasör seçme
   diyaloğu: mevcut klasörler + yeni klasör girişi. Kalıcı klasörler için
   yeni `Folders` tablosu (schemaVersion 8) — boş klasör yaşayabilsin;
   `folderNamesProvider` tablo ∪ belge klasörleri.
4. **Rutin bildirimi:** `Routines.remindAt` (gece yarısından dakika, int,
   nullable — schemaVersion 8'e birlikte). Rutin satırında çan → saat seç;
   uzun bas/tekrar → kaldır. Planlama: seçili her hafta günü için
   `zonedSchedule` + `matchDateTimeComponents: dayOfWeekAndTime` (haftalık
   tekrar); bildirim id = 100000 + routineId*10 + weekday (task id'leriyle
   çakışmaz). Rutin silinince/kapatılınca cancel.
5. **Seri + rozetler:** RoutineChecks'ten hesaplanır (şema değişikliği yok,
   durum saklanmaz). Seri = bugünden geriye planlı günlerde kesintisiz done
   (planlı olmayan gün seriyi BOZMAZ). Rozet eşikleri 3/7/14/30/100 (en uzun
   geçmiş seriden). UI: rutin satırında 🔥N, eşik geçince kutlama snackbar,
   geçmiş diyaloğunda rozet rafı. Ayarlar → "Seri ve rozetler" anahtarı
   (SharedPreferences 'streaksEnabled', varsayılan açık; kapalıyken hiçbir
   seri/rozet öğesi gösterilmez).

Sürüm yayını: pubspec `1.1.0+3`, AAB → önce kapalı test kanalına.

## Sürüm 1.2 — UYGULANDI (dev APK'da test bekliyor)

Yeni not pop-up'ı + şablon sistemi. Şema **v9** (Templates tablosu). Kod
derleniyor, `flutter analyze` temiz, dev APK üretildi. Yapılanlar:

1. **Sayfa yönü altyapısı** (`editor_state.dart`): merkezî `kPageSizes`
   kataloğu + `aspectForPageSize(id)` (yükseklik ÷ genişlik). Değerler:
   a4=1.414, **yatay** (A4 landscape)=0.7072, kare=1.0, **telefon**
   (~19.5:9)=2.1667. Editör (`note_editor_screen`) ve `pdf_export` artık bu
   helper'ı kullanır (eski sabit `== 'kare' ? 1.0 : 1.414` kaldırıldı). PDF
   formatları: yatay → A4 landscape, telefon → uzun özel format, kare → kare.
   `pageSizeOptionFor(id)` de var. Bilinmeyen/eski 'serbest' → A4.
2. **Templates tablosu** (schemaVersion 9, `Templates`): `title, pageSize,
   pageColor, body (Delta JSON), strokes (JSON dizisi), createdAt`. Yalnızca
   **kullanıcının** kaydettikleri ("Şablonlarım") burada; gömülü hazır
   şablonlar koddadır. `TemplateRepository` (add/watchAll/delete) +
   `templateRepositoryProvider` + `userTemplatesProvider`. Migration
   `from < 9 → createTable(templates)`.
3. **Gömülü hazır şablonlar** (`features/templates/templates_data.dart`):
   `NoteTemplate` modeli (id, kategori, TR/EN ad, ikon, pageSize, pageColor,
   `buildBody(bool en)`) + `_Delta` builder (title/heading/para/bullet/check —
   `size`/`bold`/`list` öznitelikleri, editör+PDF export ikisi de render eder).
   Kategoriler `kTemplateCategories` (temel/yazi/planlar/is/benim). İçerik
   **dile göre** (TR/EN). Şablonlar: Yapılacaklar, Basit not, Günlük, Fikir
   defteri, Günlük plan, Haftalık plan (yatay), Alışveriş (telefon), Toplantı
   notu, Cornell, Proje görevleri.
4. **Yeni not diyaloğu** (`features/library/new_note_dialog.dart`,
   `showNewNoteDialog`): eski `_pickNoteSize` alt sayfası KALDIRILDI. Zengin
   diyalog — not adı (opsiyonel) + sayfa boyutu çipleri + kağıt rengi
   noktaları + kategori sekmeleri + şablon ızgarası (Wrap, kapak yok). Şablon
   seçince sayfa boyutu/rengi otomatik o şablonunki olur (kullanıcı yine
   override edebilir). 'temel' sekmesinde ilk kutu = **Boş sayfa**. 'benim'
   sekmesi kullanıcı şablonları (uzun bas → sil). Onayda
   `createConfiguredNote` (actions.dart): notu body+pageSize+pageColor +
   (şablon) çizimleriyle oluşturup açar. `createNote` artık bu diyaloğu açar.
5. **Şablon olarak kaydet** (`features/templates/save_template.dart`,
   `saveNoteAsTemplate`): not paylaş menüsünde (üst bar, yalnız notlarda) →
   ad sor (başlıkla dolu) → mevcut body+pageSize+pageColor+çizimleri Templates
   tablosuna yaz → "Şablonlarım" sekmesinde görünür. Snackbar onayı.

**Bilinen sınır/ödünleşim:** şablon seçimi sekmeler arası korunur (başka
kategoriye geçince o an seçili tile görünmez ama seçim geçerli kalır — Sayfa/
Kağıt seçicileri yansıtır). Gömülü şablonlarda çizim yok; kullanıcı şablonları
çizim taşıyabilir.

### Sürüm 1.2 — şablon yeniden tasarımı (pragmatik, Claude Design handoff)

İlk şablonlar zayıftı (seçicide sadece ikon, içerik düz metin). Kullanıcı
Claude Design'da "Not Şablonları" tasarımı üretti
(`design/uygulama-not-ablonlar/`): 10 şablon telefon editörü içinde, gerçek
düzenle (çizgili kâğıt, işaretlenebilir kutucuklar, etiketli alanlar, ızgaralar).
Tasarım **yapısal/form notu** ima ediyor; mevcut editör flutter_quill + serbest
kalem olduğundan ızgara/2-kolon düzenler birebir çıkmaz. **Karar: pragmatik yol**
(metin + bölüm etiketi + kutucuk + kâğıt deseni; gerçek ızgaralar tablo bloğu
1.3'e ertelendi). Şema **v10**. Yapılanlar:

1. **Kâğıt paleti** (`editor_state.dart` `kPaperStyles`) design THEMES'e hizalandı
   (white/cream/mint/black) ve `PaperStyle`'a `line`/`muted`/`faint` renkleri
   eklendi (arka plan çizgisi + soluk etiket + hafif dolgu; kâğıda göre).
2. **Sayfa deseni** (`pageBackground`: duz/cizgili/kareli/noktali) — Documents +
   Templates'e kolon (v10 migration). Ortak `paintPageBackground()`
   (`editor_state.dart`) editör (`_PageBackgroundPainter`, metin+çizim arkasında)
   ve `pdf_export` (`_renderPageImage`) tarafından çizilir → ekranda ne varsa
   PDF'te de. Aralıklar sayfa genişliğine oranlı. **Not:** PDF export hâlâ beyaz
   zemin + koyu mürekkep kullanıyor (kâğıt rengi export sadakati ayrı iş);
   sadece desen eklendi.
3. **Arka plan seçici:** pen bar kâğıt düğmesi menüsüne "Sayfa deseni" bölümü
   (`_setBg` → `setPageBackground`).
4. **Şablonlar yeniden** (`templates_data.dart`): kategoriler design'la birebir
   (Temel 1 + Boş sayfa tile; Yazı 2; Planlar 3; İş 3). `NoteTemplate.pageBackground`
   eklendi; gövdeler bölüm etiketi (küçük büyük-harf)/checklist/çizgili-noktalı
   arka planla zenginleşti. Renk özniteliği YOK → yazı rengi kâğıda göre kalır.
   **Sadeleştirilmiş:** Haftalık plan + Cornell (gerçek ızgara/2-kolon tablo
   bloğu 1.3'te).
5. **Gerçek önizleme kartları** (`new_note_dialog.dart` `_TemplatePreview` +
   `_PreviewPainter` + `_previewLines`): her tile artık doğru en/boy oranında,
   kâğıt renginde, desenli mini sayfa + içeriğin şematik satırları (başlık/
   etiket/paragraf/kutucuk/madde çubukları). Boş sayfa tile'ı o anki boyut/
   renkte boş önizleme.

## YOL HARİTASI — genel tablo (nerede olduğumuz)

**Sürüm durumları (üç kanal):**

| Kanal | Sürüm | Durum |
|-------|-------|-------|
| Play üretim | 1.0 (mağazada) | Yayında |
| Play kapalı test | 1.1 (pubspec 1.1.0+3) | Yayın bekliyor |
| Dev / paralel APK | 1.2 + şablon tasarımı + 1.3 tablo v1 | **Aktif geliştirme burada** |

**Strateji (kullanıcı kararı):** tüm geliştirme dev APK üzerinden; biriken her
şey (1.1 + 1.2 + …) kapalı testten geçince **tek AAB** olarak yayınlanır.
Prod'a ara sürüm çıkılmaz.

**Tamamlanan:** 1.1 (varsayılan yazı modu, paylaşımı durdur, klasöre taşı, rutin
bildirimi, seri/rozet) · 1.2 (yeni not pop-up, şablon sistemi, sayfa yönleri) ·
1.2 şablon yeniden tasarımı (kâğıt paleti, sayfa desenleri, önizleme kartları) ·
**1.3 tablo bloğu v1** (ndtable embed; Haftalık/Cornell/Günlük plan/Toplantı/
Alışveriş gerçek form düzeninde — ayrıntı aşağıda).

## PLANLANAN — sonraki işler (sıralı)

### Tasarımdaki "form/yapısal sayfa" hedefine giden yol

Claude Design'daki şablonlar **etkileşimli form** (ızgara, 2-kolon, etiketli
alan, saat çizelgesi). Mevcut editör flutter_quill + serbest kalem olduğundan
bunlar birebir çıkmıyor. Tasarıma ulaşmanın **tek büyük kaldıracı = tablo/ızgara
bloğu**. O gelince Haftalık (7-sütun), Cornell (2-kolon), Günlük plan (saat
çizelgesi), Toplantı (alanlar) **gerçek** olur.

**1.3 — FORM-NOT SAYFALARI — UYGULANDI (dev APK'da test bekliyor):**

İlk deneme (ndtable: Quill'e gömülü tablo embed'i) sahada BAŞARISIZ oldu —
imleç embed hizasına giriyor, embed satırına yazılan harfler tablonun yanına
dikey akıyordu (Quill metin akışı + dev WidgetSpan + dokunmatik düzenleme
uyumsuz). **Karar: şablon sayfaları Quill'e gömülmez; native form sayfası
olarak çizilir.**

- **`features/forms/form_model.dart`:** `FormDoc` — gövde
  `{"ndform":1,"blocks":[...]}` olarak Documents.body'de durur (kaydetme,
  canlı paylaşım LWW, .ntdl, şablon kaydetme otomatik taşır). Blok tipleri:
  `title` (sayaçlı: done n/m veya count+birim) · `fields` (etiket + altı
  çizili alan, flex kolonlar) · `label` (küçük büyük-harf bölüm etiketi) ·
  `check` (kutucuklu satırlar; sağ küçük alan: adet '1'/'Kim?'; opsiyonel
  "satır ekle") · `num` (numaralı çipli satırlar) · `area` (çizgili çok
  satırlı alan) · `mood` (ruh hâli daireleri) · `hours` (saat çizelgesi) ·
  `week` (7 kolon gün kartları, hafta sonu faint) · `cornell` (2 kolon +
  özet kutusu) · `sketch` (kesikli çerçeve + noktalı eskiz kutusu).
- **`features/forms/form_page.dart`:** blokların native Flutter karşılığı —
  gerçek TextField'lar (klavye/odak sorunsuz), kutucuk/mood dokunuşları,
  kâğıt rengine duyarlı (paper.line/muted/faint). `didUpdateWidget` uzak
  güncellemede controller metinlerini eşitler.
- **Editör entegrasyonu (`note_editor_screen`):** `isFormBody(body)` ise
  Quill yerine `FormPage` (aynı sayfa zarfı: arka plan deseni + DrawingLayer
  üstte → kalemle çizim form üzerinde de çalışır). `_save`/`_applyRemoteUpdate`
  form yolu; form notlarında `activeQuillControllerProvider` set edilmez.
  Form alanları yalnızca **yazı modunda** düzenlenebilir.
- **PDF export:** `_paintForm` — tüm blokları canvas'a çizer (FormPage
  düzeninin birebir PDF karşılığı).
- **Şablonlar:** 9 gömülü şablonun tamamı form üretir (Boş sayfa Quill kalır):
  Yapılacaklar (sayaç+tarih+8 görev+ekle), Günlük (GÜNLÜK etiketi+tarih
  başlığı+ruh hâli+çizgili alan), Fikir defteri (tek cümle/neden önemli/
  adımlar/eskiz kutusu), Günlük plan (öncelik çipleri+07-18 çizelge),
  Haftalık plan (hafta/hedef+7 gün ızgarası), Alışveriş (3 kategori+adet),
  Toplantı (alanlar+gündem+aksiyon/Kim?), Cornell, Proje görevleri
  (yapılacak/devam/tamam bölümleri).
- `plainTextFromBody` form metnini çıkarır (arama/önizleme); yeni-not
  önizleme kartları form bloklarını şematiğe çevirir.
- **ndtable embed kodu duruyor** (`table_embed.dart` hâlâ kayıtlı — eski test
  notları bozulmasın); yeni şablonlar onu KULLANMAZ. İleride tamamen
  kaldırılabilir.

**Sayfa modeli + ölçek (saha geri bildirimi sonrası yeniden kuruldu):**
- **Bağımsız sayfa kartları:** `_Sheet` artık her sayfayı ayrı kart çizer
  (kendi zemin/kenarlık/gölge/desen), aralarda gerçek boşluk
  (`kPageGapRatio = 0.05 × genişlik`). Eski sürekli-tabaka + bant ayracı
  (`_PageLinesPainter`) KALDIRILDI.
- **Sayfa sayısı MANUEL (form notları; kullanıcı kararı):** form açılınca
  otomatik büyümez. `createConfiguredNote` oluştururken `formNaturalPageCount`
  ile içeriğe yetecek sayfa sayısını hesaplayıp `pageCount`'a yazar. İçerik
  (satır ekleyince) son sayfayı aşarsa `paginateForm(maxPages: pageCount)`
  boşluk atlamadan bırakır → içerik son kartın altından taşar; kullanıcı
  **"Yeni sayfa"** düğmesiyle yer açar (pageCount++). Metrikler `formMetrics()`
  (ekran + doğal sayı + PDF export ortak). **Quill (serbest) notlar** hâlâ
  post-frame ölçümle (`_quillKey` → RenderBox) otomatik büyür — akışkan metin
  için manuel sayfa mantıksız. **PDF export** form içeriğini tam sayfalar
  (maxPages YOK) → çıktıda kırpma olmaz.
- **Form sayfalama (satır-birimli):** `paginateForm` en küçük birim olarak
  blok VEYA satır kullanır (`FormUnit{block,row,page,top,spacerBefore}`).
  Satırlı bloklar (checklist/numaralı/saat) **satır satır bölünür** — sığan
  satırlar sayfada kalır, yalnız taşanlar sonraki sayfaya akar (eski hata:
  tüm liste topluca atlayıp 1. sayfayı boş bırakıyordu). Diğer bloklar bütün
  olarak atlar. `row == -1` = bütün blok. FormPage satır spacer'larını
  `layout.spacerFor(block,row)` ile içeride ekler; PDF `_paintForm` birim
  bazlı çizer (checkRow/numRow/hourRow). Ekran ve PDF **aynı sanal
  metriklerle** sayfalar.
- **Sanal genişlik ölçeği:** formlar `formVirtualWidth` (a4/kare 520 ·
  yatay 735 · telefon 390) genişliğinde dizilir, ekrana FittedBox'la
  oranlanır → Haftalık plan ekrana sığar; A4 çıktıda ~16pt gövde yazısı
  (gerçekçi yoğunluk). PDF export ölçeği aynı sanal genişlikten türetilir.
- **Çizgi hizası:** çizgili alanlarda çizgiler yazının taban çizgisine
  (`ruledBaseline`) oturur (ekran + PDF).
- **PDF çizim dilimi:** çizimler sürekli düzlemde (sayfalar + aralıklar);
  export her sayfada `strokeOffsetY = i × (aspect + kPageGapRatio) × w`
  kaydırmasıyla doğru dilimi basar (eski `s.page==i` filtresi kaldırıldı —
  çok sayfalı çizimler artık PDF'te kaybolmaz).

**1.3 kalanlar (cila):**
- Form notlarında Aa biçim düğmeleri fiilen işlemez (form alanları düz metin;
  kullanıcı kararı: bar GİZLENMEDİ, çökme yok çünkü `activeQuillControllerProvider`
  form notunda null → format barı zaten görünmez). Gerçek biçimlendirme =
  form yazı alanlarını zengin-metin yapmak (ayrı büyük iş, sırada).
- PDF export kâğıt rengi hâlâ beyaz (desen + form çiziliyor; renk ayrı iş —
  kullanıcı kararı: "hafif ton" varsayılanı, sırası gelince).
- Quill (serbest) notlarda metin sayfa sınırını hâlâ ortalayabilir (form
  sayfalaması yalnız form bloklarında; Quill satır-bazlı sayfalama yapılmadı).

**Cila paketi — UYGULANDI (dev APK):**
- **Yeni-not "Temel" sekmesi:** Boş sayfa + **Çizgili/Kareli/Noktalı** boş kâğıt
  kutuları (`new_note_dialog`); seçilen desen `_pageBackground`'a yazılır, blank
  Quill notu o desenle açılır. Önizleme deseni gösterir.
- **Checklist satır silme:** kutucuğa **uzun bas → satırı sil** (`_checkbox`
  onLongPress; tek satır kalınca kapalı). "Geri al" snackbar'ı. Index tabanlı
  controller'lar silme/geri-al sonrası `_clearBlockCtrls` ile yeniden kurulur.
- **Öksüz etiket:** `paginateForm`'da `LabelBlock` `keepWith: firstUnitHeight`
  ile sonraki ilk içerikle birlikte kalır (etiket sayfa dibinde tek kalmaz).

**1.4 — Tasarım cilası (tam sadakat, opsiyonel/1.3 sonrası):**
- Etiketli alan bloğu (TARİH ____ gibi hizalı alanlar), bölüm etiketi rengi
  (kâğıda uyan muted — kalıcı çözüm için renk özniteliği yerine "label" blok
  stili), ruh hâli satırı, eskiz kutusu, alışverişte adet sütunu.
- **PDF export kâğıt rengi + arka plan sadakati** (şu an beyaz zemin + koyu
  mürekkep; kâğıt rengi/deseni PDF'e yansıtılacak — `_renderPageImage`'e ink +
  paper.background threading).
- Yeni-not diyaloğu stilini design'a tam getirme (kâğıt noktaları büyük halka,
  kategori sekmesi koyu-pill vurgusu).

### HESAPLAR & SENKRON (kullanıcı onayladı — planlandı, sıraya alındı)

**Kararlar (kullanıcı):** giriş **OPSİYONEL** (offline-first korunur; hesapsız
tam çalışır, giriş yalnız senkron+collab için) · **e-posta kodu (parolasız,
6 haneli OTP)** — parola yönetimi yok, uygulamadaki "kodla nota katıl" desenine
benzer. Temel zaten var: Supabase kurulu (şu an collab için **anonim** giriş),
`shared_notes`/`note_members`/`shared_strokes` + RLS mevcut; drift yerel DB.

**⏸️ ASKIYA ALINDI (kullanıcı kararı):** Faz 1 KODU tamam ve pushlı; ancak
**e-posta gönderimi (SMTP) kurulumu** kullanıcının Supabase panelinde yapması
gereken bir adım olduğu ve şablon/kod ayarında takıldığı için **mail
entegrasyonu şimdilik ertelendi**. Devam etmek için: kullanıcı custom SMTP
(Brevo domainsiz / Resend + domain) kurar → e-posta şablonlarına `{{ .Token }}`
ekler (bkz. `SETUP-AUTH.md`). O gün gelince kod hazır, test edilip Faz 2'ye
geçilebilir. Şu an odak: **uygulama içi pürüzler + yeni özellikler.**

**Faz 1 — E-posta girişi + profil — UYGULANDI (mail SMTP kurulumu bekliyor):**
- **`features/auth/auth_service.dart`:** `AuthService.sendCode/verifyCode/
  setDisplayName/signOut`. `signInWithOtp` (yeni kullanıcı) veya anonim oturum
  varsa `updateUser(email)` → `verifyOTP(type: emailChange)` ile **anonim
  oturumu kalıcı hesaba yükseltir** (uid korunur → collab verisi kaybolmaz).
  `accountProvider` (StreamProvider `onAuthStateChange` → `NdAccount?`; anon =
  giriş yok sayılır), `needsDisplayNameProvider`, `authErrorText` tanılama.
  **Görünen ad Supabase user metadata'sında** (`display_name`) — Faz 1'de ayrı
  profiles tablosu YOK; başkalarının görmesi Faz 2.
- **`features/auth/auth_ui.dart`:** `showSignInSheet` — adım adım e-posta →
  6 haneli kod → görünen ad (alt sayfa). Onboarding + Ayarlar'dan çağrılır.
- **Ayarlar:** temsilî "Bağlan" kartı KALDIRILDI → `_AccountCard` (girişsiz:
  "Giriş yap / Kaydol"; girişli: avatar + ad + e-posta + "Çıkış").
- **Onboarding yeniden:** `onboarding_screen` artık özellik turu (Hazır
  şablonlar · Yaz&çiz · PDF · Rutinler&hatırlatıcılar · Senkron) küçük
  illüstrasyon kartlarıyla; son slaytta "Giriş yap / Kaydol" (`showSignInSheet`)
  + "Şimdilik geç". Giriş opsiyonel (kapıda tutmaz).
- **Sunucu ayarı (kullanıcı yapar):** `SETUP-AUTH.md` — Supabase e-posta
  sağlayıcısı açık + e-posta şablonlarına (`Magic Link` ve `Change Email`)
  `{{ .Token }}` eklenmeli ki 6 haneli kod gelsin. Anonim giriş açık kalsın.
- **Kalan (Faz 1 cila):** görünen ad Ayarlar'dan düzenleme yok (yeniden giriş
  gerekiyor); e-posta değiştirme akışı yok.

**Faz 2 — "Kim katıldı" (collab kimlikleri):**
- Paylaşımlı notta üyelerin adı/avatarı: `note_members` ⨯ `profiles` join →
  üst barda katılımcı avatarları. Supabase Realtime **Presence** ile o an
  notu açık olanlar canlı (yeşil nokta).
- `shared_strokes`/notes olaylarına yazar uid → "kim yazdı" (opsiyonel renk).

**Faz 3 — Cihazlar arası senkron (asıl büyük iş):**
- Supabase'de kullanıcıya ait `sync_documents` + `sync_strokes` (user_id, RLS:
  yalnız sahibi). Drift şeması mirror; silme için **soft-delete** (deletedAt).
- `data/sync/` katmanı: push (yerel updatedAt > lastSync → buluta), pull (uzak
  → yerele, **LWW updatedAt** — collab gövde deseniyle tutarlı). İlk girişte
  yerel notlar buluta yüklenir; başka cihazda giriş → buluttan çekilir.
- Arka planda otomatik + Ayarlar'da "şimdi senkronla" + senkron durum
  göstergesi. Temsilî "Bağlan" gerçeğe döner (backlog'daki "gerçek bulut
  senkron" bu fazla kapanır).

**Faz 4 — Cila:** çıkış, hesap silme (GDPR/Play), çoklu cihaz yönetimi,
çakışma bildirimi.

**2.0 — Şablon mağazası:**
- Aşama 1 (önce bu): KÜRATÖRLÜ katalog — Supabase `store_templates` tablosu
  (public read; yalnızca bizim yüklediklerimiz), uygulamada mağaza sayfası +
  indir → yerel Templates'e kopyala + indirme sayacı. Moderasyon yükü yok.
- Aşama 2 (uygulama büyüyünce): kullanıcı yüklemesi — Play UGC politikası
  gereği raporla/engelle mekanizması ZORUNLU; moderasyon planı gerektirir.

### Backlog (sürüme bağlı değil, sıra bekleyen)

- **Gerçek bulut senkron** — artık "HESAPLAR & SENKRON Faz 3" olarak planlandı
  (yukarı bkz.); Ayarlar'daki "Bağlan" o fazda gerçeğe döner.
- **Kalan Türkçe metinlerin çevirisi** — klasörler/arama ekranları, bazı araç
  çubuğu tooltip'leri, `date_format` göreli tarihler henüz TR.
- **Kalıcı etiketler** — şu an statik; ayrı tablo gerekir (klasör tablosu deseni).
- **Yeni platformlar** — iOS/Windows/macOS/Linux/Web (`flutter create
  --platforms=…`; web'de drift WASM + pdfx pdf.js).
- **Küçük düzeltmeler** — dev APK test geri bildirimlerinden çıkacak liste.

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
