import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../shell/shell_state.dart';
import 'backup_service.dart';

/// **Otomatik yerel yedekleme.** Elle yedek almak kullanıcıya bırakıldığında
/// pratikte kimse almıyor; bu yüzden uygulama günde bir kez sessizce kendi
/// klasörüne yedek yazar ve son [_kKeep] kopyayı saklar.
///
/// **Sınır (bilinçli):** yedek cihazın kendi uygulama klasöründe durur. Bu,
/// yanlışlıkla silme / veri bozulması senaryolarını kurtarır ama **telefonun
/// kaybolmasını kurtarmaz** — onun için Ayarlar'daki "Dışa aktar" ile yedeği
/// telefon dışına almak gerekir. (Gerçek bulut yedeği senkron fazına bağlı.)

const _kKeep = 3; // saklanacak otomatik yedek sayısı
const _kMinInterval = Duration(hours: 24);
const _kLastKey = 'autoBackupLast'; // son yedek zamanı (ISO)
const _kEnabledKey = 'autoBackupEnabled';

/// Otomatik yedekleme açık mı? (kalıcı, varsayılan AÇIK)
class AutoBackupNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(sharedPrefsProvider).getBool(_kEnabledKey) ?? true;

  void set(bool v) {
    state = v;
    ref.read(sharedPrefsProvider).setBool(_kEnabledKey, v);
  }
}

final autoBackupEnabledProvider =
    NotifierProvider<AutoBackupNotifier, bool>(AutoBackupNotifier.new);

Directory? _dirCache;

/// Otomatik yedeklerin tutulduğu klasör.
Future<Directory> autoBackupDir() async {
  if (_dirCache != null) return _dirCache!;
  final base = await getApplicationDocumentsDirectory();
  final dir = Directory('${base.path}/backups');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  return _dirCache = dir;
}

/// Mevcut otomatik yedekler — **yeniden eskiye** sıralı.
Future<List<File>> autoBackupFiles() async {
  final dir = await autoBackupDir();
  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.ntdlbak'))
      .toList();
  files.sort((a, b) => b.path.compareTo(a.path)); // ad = zaman damgası
  return files;
}

String _p2(int n) => n.toString().padLeft(2, '0');

/// Gerekliyse (açık + son yedeğin üstünden 24 saat geçmiş) sessizce yedek alır.
/// Uygulama açılışında çağrılır; hata durumunda **sessizce** vazgeçer —
/// yedekleme başarısızlığı kullanıcının işini bölmemeli.
Future<void> runAutoBackupIfDue(WidgetRef ref) async {
  try {
    if (!ref.read(autoBackupEnabledProvider)) return;
    final prefs = ref.read(sharedPrefsProvider);
    final last = DateTime.tryParse(prefs.getString(_kLastKey) ?? '');
    final now = DateTime.now();
    if (last != null && now.difference(last) < _kMinInterval) return;

    final data = await collectBackupData(ref);
    // Boş uygulamada yedek dosyası üretmenin anlamı yok.
    if ((data['notes'] as List?)?.isEmpty ?? true) {
      await prefs.setString(_kLastKey, now.toIso8601String());
      return;
    }

    final dir = await autoBackupDir();
    final name = 'oto-${now.year}${_p2(now.month)}${_p2(now.day)}'
        '-${_p2(now.hour)}${_p2(now.minute)}.ntdlbak';
    await File('${dir.path}/$name').writeAsString(jsonEncode(data));
    await prefs.setString(_kLastKey, now.toIso8601String());

    // Eskileri sil (en yeni [_kKeep] tanesi kalır).
    final files = await autoBackupFiles();
    for (final f in files.skip(_kKeep)) {
      try {
        f.deleteSync();
      } catch (_) {
        // Silinemeyen dosya sorun değil; bir sonraki turda tekrar denenir.
      }
    }
  } catch (_) {
    // Sessiz: otomatik yedek en iyi çabadır.
  }
}

/// Son otomatik yedeğin zamanı (yoksa null) — Ayarlar'da gösterilir.
Future<DateTime?> lastAutoBackupTime(WidgetRef ref) async {
  final files = await autoBackupFiles();
  if (files.isEmpty) return null;
  try {
    return files.first.statSync().modified;
  } catch (_) {
    return null;
  }
}

/// Uygulama açılışında otomatik yedeği tetikleyen görünmez widget.
class AutoBackupRunner extends ConsumerStatefulWidget {
  const AutoBackupRunner({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AutoBackupRunner> createState() => _AutoBackupRunnerState();
}

class _AutoBackupRunnerState extends ConsumerState<AutoBackupRunner> {
  @override
  void initState() {
    super.initState();
    // İlk kareyi bekle: açılış animasyonu yedekleme yüzünden takılmasın.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) runAutoBackupIfDue(ref);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
