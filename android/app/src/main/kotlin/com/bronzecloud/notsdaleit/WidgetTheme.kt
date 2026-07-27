package com.bronzecloud.notsdaleit

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri

/**
 * Widget renkleri — **tasarımdan** gelir:
 * `design/Android widget tasarımı isteniyor/Widgetlar.dc.html`.
 *
 * Bunlar uygulamanın `nd_colors.dart` token'ları DEĞİL; tasarımın widget'lar
 * için ayrıca belirlediği paleti. (Yakınlar ama birebir değil: ör. açık tema
 * vurgusu tasarımda #1B2A42, uygulamada #193769.) Tasarım kazanır.
 *
 * Yarı saydam katmanlar (rgba) burada **zemine yedirilmiş düz renk** olarak
 * duruyor — RemoteViews'te katman karıştırma yok, şekiller shape drawable.
 *
 * Tema **uygulamanın** seçimini izler, sistemin değil. Tasarım notu
 * `values`/`values-night` diyor ama kullanıcı uygulamada açık tema seçtiğinde
 * telefon koyu temada olsa bile widget açık kalmalı; bu yüzden renkler burada
 * seçilip RemoteViews'e tek tek uygulanıyor.
 */
data class WidgetPalette(
    /** Widget yüzeyi — 22dp köşe, ince kenarlık. */
    val surfaceRes: Int,
    /** "Yeni not" kartı — accent dolgu. */
    val accentCardRes: Int,
    /** Son notlar ızgarasındaki iç kart — 12dp köşe. */
    val innerRes: Int,
    /** Kısayol ikon çipi. */
    val chipRes: Int,
    /** Seri (streak) rozeti — tam yuvarlak. */
    val pillRes: Int,
    /** Son notlar başlığındaki "+" düğmesi — accent dolgu. */
    val addBtnRes: Int,
    /** Logo işaretinin zemini. */
    val logoRes: Int,
    /** "Yeni not" kartındaki ikon dairesi. */
    val circleRes: Int,
    /** Yapılmış rutin — dolu accent daire. */
    val checkFillRes: Int,
    /** Yapılmamış rutin — boş halka. */
    val checkRingRes: Int,
    /** PDF rozeti zemini. */
    val badgeRes: Int,
    val text: Int,
    val text2: Int,
    /** Üçüncül metin ("+2 rutin daha"). */
    val text3: Int,
    val accent: Int,
    /** Accent dolgunun üstündeki metin/ikon. */
    val onAccent: Int,
    /** "Yeni not" kartındaki ikincil satır ("notsdaleit"). */
    val onAccent2: Int,
    /** Logo işaretinin içindeki dağın rengi. */
    val onLogo: Int,
    /** Kısayollar arasındaki dikey ayraç. */
    val divider: Int,
) {
    companion object {
        fun of(dark: Boolean): WidgetPalette = if (dark) {
            WidgetPalette(
                surfaceRes = R.drawable.widget_surface_dark,
                accentCardRes = R.drawable.widget_accent_dark,
                innerRes = R.drawable.widget_inner_dark,
                chipRes = R.drawable.widget_chip_dark,
                pillRes = R.drawable.widget_pill_dark,
                addBtnRes = R.drawable.widget_addbtn_dark,
                logoRes = R.drawable.widget_logo_dark,
                circleRes = R.drawable.widget_circle_dark,
                checkFillRes = R.drawable.widget_check_fill_dark,
                checkRingRes = R.drawable.widget_check_ring_dark,
                badgeRes = R.drawable.widget_badge_dark,
                text = 0xFFF2EDE6.toInt(),
                text2 = 0xFF8D857A.toInt(),
                text3 = 0xFFA79E93.toInt(),
                accent = 0xFFA3B2D2.toInt(),
                onAccent = 0xFF141C2E.toInt(),
                onAccent2 = 0xFF404B64.toInt(),
                onLogo = 0xFF1B2A42.toInt(),
                divider = 0xFF33312C.toInt(),
            )
        } else {
            WidgetPalette(
                surfaceRes = R.drawable.widget_surface_light,
                accentCardRes = R.drawable.widget_accent_light,
                innerRes = R.drawable.widget_inner_light,
                chipRes = R.drawable.widget_chip_light,
                pillRes = R.drawable.widget_pill_light,
                addBtnRes = R.drawable.widget_addbtn_light,
                logoRes = R.drawable.widget_logo_light,
                circleRes = R.drawable.widget_circle_light,
                checkFillRes = R.drawable.widget_check_fill_light,
                checkRingRes = R.drawable.widget_check_ring_light,
                badgeRes = R.drawable.widget_badge_light,
                text = 0xFF1B1713.toInt(),
                text2 = 0xFF8B8377.toInt(),
                text3 = 0xFF7C7468.toInt(),
                accent = 0xFF1B2A42.toInt(),
                onAccent = 0xFFF5F1E9.toInt(),
                onAccent2 = 0xFF9EA1A6.toInt(),
                onLogo = 0xFFF5F1E9.toInt(),
                divider = 0xFFE7E3DD.toInt(),
            )
        }
    }
}

/**
 * Metnin üstü çizili çizilmesi (yapılmış rutin) — tasarımdaki
 * `text-decoration: line-through` karşılığı.
 *
 * RemoteViews'te doğrudan bir API yok; `TextView.setPaintFlags(int)` `setInt`
 * ile çağrılabiliyor. `Paint.ANTI_ALIAS_FLAG` = 1, `STRIKE_THRU_TEXT_FLAG` = 16.
 */
object PaintFlags {
    const val PLAIN = android.graphics.Paint.ANTI_ALIAS_FLAG
    const val STRIKE =
        android.graphics.Paint.ANTI_ALIAS_FLAG or android.graphics.Paint.STRIKE_THRU_TEXT_FLAG
}

/** Widget metinleri. Dil uygulamadan gelir (kullanıcı Ayarlar'dan seçer). */
object WidgetText {
    fun t(lang: String, tr: String, en: String): String = if (lang == "en") en else tr
}

/**
 * Widget'tan uygulamayı bir eylemle açan PendingIntent.
 *
 * **Dikkat:** `PendingIntent` eşitliği extra'lara BAKMAZ; yalnızca action/data/
 * type/component'e bakar. Bu yüzden her eylem hem farklı bir `requestCode` hem
 * de farklı bir `data` URI'si alır — yoksa dört kısayol tek eyleme çökerdi.
 */
object WidgetIntents {

    fun launch(context: Context, action: String, requestCode: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            this.action = MainActivity.ACTION_WIDGET
            // singleTask: uygulama açıksa yeni kopya açılmaz, onNewIntent'e düşer.
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            data = Uri.parse("ndwidget://launch/$action")
            putExtra(MainActivity.EXTRA_ACTION, action)
        }
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            // FLAG_IMMUTABLE API 31+ zorunlu.
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    /** Rutini widget'tan işaretleyen yayın (uygulama açılmaz). */
    fun toggleRoutine(
        context: Context,
        routineId: Int,
        currentlyDone: Boolean,
    ): PendingIntent {
        val intent = Intent(context, RoutinesWidgetProvider::class.java).apply {
            action = RoutinesWidgetProvider.ACTION_TOGGLE
            data = Uri.parse("ndwidget://routine/$routineId")
            putExtra(RoutinesWidgetProvider.EXTRA_ROUTINE_ID, routineId)
            putExtra(RoutinesWidgetProvider.EXTRA_DONE, currentlyDone)
        }
        return PendingIntent.getBroadcast(
            context,
            REQ_ROUTINE_BASE + routineId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    // Eylem adları — Dart tarafındaki `home_widget_bridge` ile aynı olmalı.
    const val NEW_NOTE = "newNote"
    const val NEW_DRAWING = "newDrawing"
    const val SEARCH = "search"
    const val CALENDAR = "calendar"
    const val ROUTINES = "routines"
    const val LIBRARY = "library"

    /** `openNote:<id>` — son notlar widget'ından belge açma. */
    fun openNote(id: Int) = "openNote:$id"

    // requestCode aralıkları (çakışma olmasın diye ayrıldı).
    const val REQ_QUICK_NOTE = 100
    const val REQ_SHORTCUT_BASE = 200
    const val REQ_ROUTINES_HEADER = 300
    const val REQ_RECENT_HEADER = 400
    const val REQ_RECENT_NEW = 401
    const val REQ_NOTE_BASE = 1_000_000
    const val REQ_ROUTINE_BASE = 2_000_000
}
