# notsdaleit

**Free, open-source, ad-free notes + PDF annotation + drawing app with
real-time collaboration.** Built with Flutter.

Ücretsiz, açık kaynak, reklamsız not + PDF işaretleme + çizim uygulaması —
gerçek zamanlı ortak not desteğiyle. (Türkçe özet aşağıda.)

## Features

- 📝 **Rich text + pen on the same page** — bold/italic/underline/strike,
  bullet & check lists, font family & size; draw with pen, highlighter and
  eraser on the same paper (A4 or square, white/yellow/green/black).
- 📄 **PDF viewing & annotation** — import PDFs, draw on top of pages.
- 🤝 **Live shared notes** — share a note with a 6-character code; strokes
  appear on the other device in real time, text syncs within ~1 s.
  No account needed (anonymous identity). Backed by
  [Supabase](https://supabase.com) (open source).
- 📅 **Calendar & reminders** — tasks with exact-time notifications, day notes.
- 🔁 **Routines** — habit checklists that reset daily (or on chosen weekdays),
  with a monthly history calendar.
- 🌗 Light/dark theme · 🇹🇷/🇬🇧 Turkish & English · fully **offline-first**
  (SQLite via drift) · `.ntdl` template export/import · export to PDF.
- 🚫 No ads, no analytics, no tracking. See [PRIVACY.md](PRIVACY.md).

## Building from source

Requirements: Flutter 3.29.x (Dart 3.7).

```bash
flutter pub get
dart run build_runner build   # drift code generation
flutter build apk --release
```

### Live collaboration backend (optional)

The live-sharing feature needs a (free) Supabase project:

1. Create a project at supabase.com and run [`supabase/setup.sql`](supabase/setup.sql)
   in the SQL Editor.
2. Enable **Anonymous sign-ins** (Authentication → Sign In / Providers).
3. Put your Project URL and anon/publishable key into
   [`lib/core/collab/collab_config.dart`](lib/core/collab/collab_config.dart).

If the config is left empty the feature is fully disabled and the app works
100 % offline. Step-by-step guide (Turkish): [SETUP-COLLAB.md](SETUP-COLLAB.md).

> Note: the Supabase **anon key is designed to be public** (it ships inside
> every released APK). Data is protected by Postgres Row Level Security —
> a note is only accessible to people who joined it with its share code.

## Contributing

Issues and pull requests are welcome — see
[CONTRIBUTING.md](CONTRIBUTING.md). The codebase notes in
[CLAUDE.md](CLAUDE.md) (Turkish) describe the architecture in detail.

## License

[GPL-3.0-or-later](LICENSE). You may use, study, share and improve this app;
derivative works must remain free software under the same license.

---

## Türkçe

notsdaleit; not tutma, PDF üzerine işaretleme ve kalemle çizimi tek uygulamada
birleştirir. Bir notu 6 haneli kodla ikinci bir kişiyle **canlı** paylaşabilir,
çizimleri anlık görebilirsiniz. Takvim + hatırlatıcılar ve rutin (alışkanlık)
takibi içerir. Tamamen çevrimdışı çalışır; canlı paylaşım isteğe bağlıdır.
Reklamsız, ücretsiz ve açık kaynaktır (GPL-3.0). Gizlilik:
[PRIVACY.md](PRIVACY.md) · Katkı: [CONTRIBUTING.md](CONTRIBUTING.md) ·
Mimari notları: [CLAUDE.md](CLAUDE.md).
