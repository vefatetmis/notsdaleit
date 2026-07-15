# Contributing / Katkı

Thanks for your interest! / İlginiz için teşekkürler!

## English

- **Bugs & ideas:** open a GitHub Issue. Please include device/Android
  version and steps to reproduce.
- **Pull requests:** keep them focused (one topic per PR). Before submitting:
  ```bash
  flutter analyze          # must be clean
  dart run build_runner build   # if you touched lib/data/database/database.dart
  ```
- **Architecture:** feature-first layout under `lib/features/`, state via
  Riverpod, local storage via drift (SQLite). Detailed (Turkish) architecture
  notes live in [CLAUDE.md](CLAUDE.md).
- **Schema changes:** bump `schemaVersion` in
  `lib/data/database/database.dart` and add a migration.
- **Strings:** every user-visible string must use `context.t('Türkçe', 'English')`.
- **License:** by contributing you agree your work is licensed under
  GPL-3.0-or-later.

## Türkçe

- **Hata ve öneriler:** GitHub Issue açın (cihaz/Android sürümü ve
  tekrarlama adımlarıyla).
- **PR'lar:** tek konuya odaklı olsun. Göndermeden önce `flutter analyze`
  temiz çıkmalı; veritabanı şemasına dokunduysanız `dart run build_runner
  build` çalıştırın ve `schemaVersion` + migration ekleyin.
- **Metinler:** kullanıcıya görünen her metin `context.t('Türkçe','English')`
  ile iki dilli yazılmalı.
- Mimari ayrıntıları için [CLAUDE.md](CLAUDE.md)'ye bakın.
