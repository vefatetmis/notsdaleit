import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/collab/collab_config.dart';
import 'core/notifications/notification_service.dart';
import 'features/shell/shell_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  await NotificationService.instance.init();

  // Canlı ortak not: yalnızca yapılandırma doluysa bağlan (bkz. SETUP-COLLAB.md).
  if (CollabConfig.enabled) {
    try {
      if (CollabConfig.isPublishableKey) {
        await Supabase.initialize(
          url: CollabConfig.url,
          publishableKey: CollabConfig.anonKey,
        );
      } else {
        // Eski tür (JWT) anon anahtarı.
        await Supabase.initialize(
          url: CollabConfig.url,
          // ignore: deprecated_member_use
          anonKey: CollabConfig.anonKey,
        );
      }
    } catch (_) {
      // Ağ yoksa vb. — uygulama çevrimdışı çalışmaya devam eder.
    }
  }

  // Provider container'ı elde tutuyoruz ki aynı veritabanı uygulama boyunca
  // yaşasın. (Örnek not tohumlaması kaldırıldı — uygulama boş başlar.)
  final container = ProviderContainer(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const NotdaleitApp(),
    ),
  );
}
