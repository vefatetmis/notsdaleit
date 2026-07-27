package com.bronzecloud.notsdaleit

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Ana ekran widget'ları ile Flutter arasındaki köprü.
 *
 * **Eylem taşıma** (widget'a dokunuldu → uygulama açıldı) iki yolla olur,
 * ikisi de gerekli:
 * - **Soğuk başlatma** (uygulama kapalıydı): Flutter henüz hazır olmadığı için
 *   eylem [pendingAction]'da bekletilir; Dart hazır olunca `consumeLaunchAction`
 *   ile alır.
 * - **Sıcak başlatma** (uygulama arka plandaydı): [onNewIntent] tetiklenir ve
 *   eylem doğrudan kanaldan gönderilir.
 *
 * **Veri taşıma** (uygulama → widget) `setWidgetData` ile: Dart bir JSON anlık
 * görüntü yollar, [WidgetStore] saklar ve tüm widget'lar yeniden çizilir.
 *
 * **İşaret taşıma** (widget → uygulama) `takePendingRoutineToggles` ile:
 * widget'tan yapılan rutin işaretleri kuyrukta bekler, Dart alıp veritabanına
 * uygular.
 */
class MainActivity : FlutterActivity() {

    private var channel: MethodChannel? = null

    /** Flutter hazır olmadan gelen eylem (soğuk başlatma). */
    private var pendingAction: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        pendingAction = actionOf(intent)

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "consumeLaunchAction" -> {
                    result.success(pendingAction)
                    pendingAction = null // bir kez tüketilir
                }
                "setWidgetData" -> {
                    val json = call.arguments as? String
                    if (json != null) {
                        WidgetStore.saveData(applicationContext, json)
                        WidgetStore.refreshAll(applicationContext)
                    }
                    result.success(null)
                }
                "takePendingRoutineToggles" -> {
                    result.success(WidgetStore.takePending(applicationContext))
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val action = actionOf(intent) ?: return
        // Kanal hazır değilse (nadiren) eylem kaybolmasın.
        if (channel == null) {
            pendingAction = action
        } else {
            channel?.invokeMethod("launchAction", action)
        }
    }

    /**
     * Intent'ten widget eylemini çıkarır.
     *
     * Eski sürümden kalan ana ekran widget'ları hâlâ [ACTION_NEW_NOTE] taşıyan
     * bir PendingIntent tutuyor olabilir (kullanıcı widget'ı yeniden eklemeden
     * güncelledi) — o yol bilerek korunuyor.
     */
    private fun actionOf(intent: Intent?): String? = when (intent?.action) {
        ACTION_WIDGET -> intent.getStringExtra(EXTRA_ACTION)
        ACTION_NEW_NOTE -> "newNote"
        else -> null
    }

    companion object {
        /** Yeni, genel widget eylemi; asıl eylem [EXTRA_ACTION] extra'sındadır. */
        const val ACTION_WIDGET = "com.bronzecloud.notsdaleit.WIDGET"
        const val EXTRA_ACTION = "widgetAction"

        /** Eski (tek widget'lı) sürümün eylemi — geriye dönük uyumluluk. */
        const val ACTION_NEW_NOTE = "com.bronzecloud.notsdaleit.NEW_NOTE"

        private const val CHANNEL = "notsdaleit/widget"
    }
}
