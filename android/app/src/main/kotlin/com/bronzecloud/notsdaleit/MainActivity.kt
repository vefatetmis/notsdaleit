package com.bronzecloud.notsdaleit

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Ana ekran widget'ından gelen eylemi Flutter'a taşır.
 *
 * İki yol var, ikisi de gerekli:
 * - **Soğuk başlatma** (uygulama kapalıyken widget'a dokunuldu): Flutter henüz
 *   hazır olmadığı için eylem [pendingAction]'da bekletilir; Dart tarafı hazır
 *   olunca `consumeLaunchAction` ile alır.
 * - **Sıcak başlatma** (uygulama arka planda): [onNewIntent] tetiklenir ve
 *   eylem doğrudan kanaldan gönderilir.
 */
class MainActivity : FlutterActivity() {

    private var channel: MethodChannel? = null

    /** Flutter hazır olmadan gelen eylem (soğuk başlatma). */
    private var pendingAction: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        if (intent?.action == ACTION_NEW_NOTE) {
            pendingAction = NEW_NOTE
        }

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "consumeLaunchAction" -> {
                    result.success(pendingAction)
                    pendingAction = null // bir kez tüketilir
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.action == ACTION_NEW_NOTE) {
            // Kanal hazır değilse (nadiren) eylem kaybolmasın.
            if (channel == null) {
                pendingAction = NEW_NOTE
            } else {
                channel?.invokeMethod("launchAction", NEW_NOTE)
            }
        }
    }

    companion object {
        const val ACTION_NEW_NOTE = "com.bronzecloud.notsdaleit.NEW_NOTE"
        private const val CHANNEL = "notsdaleit/widget"
        private const val NEW_NOTE = "newNote"
    }
}
