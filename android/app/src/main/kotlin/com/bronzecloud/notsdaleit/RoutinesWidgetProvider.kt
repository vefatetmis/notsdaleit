package com.bronzecloud.notsdaleit

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews

/**
 * 4×2 **Bugünün rutinleri** widget'ı.
 *
 * Tasarım (Widgetlar.dc.html, üçüncü kart):
 * - Başlık: tekrar ikonu + başlık + **seri rozeti** (alev + gün) + `2/5` sayacı.
 * - Sayacı yansıtan ince **ilerleme çubuğu**.
 * - Üç rutin satırı: onay dairesi + başlık + hatırlatıcı saati. Yapılan satır
 *   soluk ve **üstü çizili**.
 * - Taşarsa "+N rutin daha" + ok.
 *
 * Davranış:
 * - Başlığa dokun → Rutinler ekranı.
 * - Satıra dokun → **uygulamayı açmadan** işaretle. Dokunuş
 *   [WidgetStore.toggleRoutine] ile hem görünüme (anında) hem bekleyen kuyruğa
 *   yazılır; uygulama açılınca Dart kuyruğu boşaltıp RoutineChecks'e uygular.
 *   Böylece widget çevrimdışı ve uygulama kapalıyken de çalışır.
 *
 * Gece yarısı: `DATE_CHANGED` yayınıyla liste yeniden çizilir — hangi rutinin
 * bugün planlı olduğu ve işaretler burada, gün maskesinden hesaplanır.
 */
class RoutinesWidgetProvider : AppWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_TOGGLE -> {
                val id = intent.getIntExtra(EXTRA_ROUTINE_ID, -1)
                if (id >= 0) {
                    WidgetStore.toggleRoutine(
                        context,
                        id,
                        intent.getBooleanExtra(EXTRA_DONE, false)
                    )
                    redraw(context)
                }
            }
            // Gün değişti / saat elle değiştirildi: işaretler sıfırlanmalı,
            // bugünün planlı listesi yeniden hesaplanmalı.
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED -> redraw(context)
            else -> super.onReceive(context, intent)
        }
    }

    private fun redraw(context: Context) {
        val manager = AppWidgetManager.getInstance(context) ?: return
        val ids = manager.getAppWidgetIds(
            ComponentName(context, RoutinesWidgetProvider::class.java)
        ) ?: return
        if (ids.isEmpty()) return
        onUpdate(context, manager, ids)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val data = WidgetStore.data(context)
        val pal = WidgetPalette.of(data.dark)
        val lang = data.lang
        val today = WidgetStore.routinesForToday(context, data)
        val doneCount = today.count { it.done }
        // Rozetteki seri: bugünün rutinleri arasındaki en uzun güncel seri.
        val streak = today.maxOfOrNull { it.streak } ?: 0

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_routines)

            views.setInt(R.id.rt_card, "setBackgroundResource", pal.surfaceRes)
            views.setInt(R.id.rt_header_icon, "setColorFilter", pal.accent)
            views.setTextColor(R.id.rt_header_title, pal.text)
            views.setTextColor(R.id.rt_progress, pal.text)
            views.setTextColor(R.id.rt_empty, pal.text2)
            views.setTextViewText(
                R.id.rt_header_title,
                WidgetText.t(lang, "Bugünün rutinleri", "Today's routines")
            )
            views.setOnClickPendingIntent(
                R.id.rt_header,
                WidgetIntents.launch(
                    context,
                    WidgetIntents.ROUTINES,
                    WidgetIntents.REQ_ROUTINES_HEADER
                )
            )

            // Seri rozeti — Ayarlar'da seriler kapalıysa ya da seri yoksa gizli.
            val showStreak = data.streaks && streak >= 2
            views.setViewVisibility(R.id.rt_pill, if (showStreak) View.VISIBLE else View.GONE)
            if (showStreak) {
                views.setInt(R.id.rt_pill, "setBackgroundResource", pal.pillRes)
                views.setInt(R.id.rt_flame, "setColorFilter", pal.accent)
                views.setTextColor(R.id.rt_streak, pal.accent)
                views.setTextViewText(R.id.rt_streak, streak.toString())
            }

            views.setTextViewText(
                R.id.rt_progress,
                if (today.isEmpty()) "" else "$doneCount/${today.size}"
            )

            // İlerleme çubuğu: RemoteViews'te progressDrawable değiştirilemediği
            // için tema başına ayrı bir ProgressBar var, biri gösterilir.
            val bar = if (data.dark) R.id.rt_bar_dark else R.id.rt_bar_light
            val otherBar = if (data.dark) R.id.rt_bar_light else R.id.rt_bar_dark
            views.setViewVisibility(otherBar, View.GONE)
            views.setViewVisibility(bar, if (today.isEmpty()) View.GONE else View.VISIBLE)
            if (today.isNotEmpty()) {
                views.setProgressBar(bar, today.size, doneCount, false)
            }

            val empty = today.isEmpty()
            views.setViewVisibility(R.id.rt_empty, if (empty) View.VISIBLE else View.GONE)
            views.setTextViewText(
                R.id.rt_empty,
                if (!data.hasData) {
                    WidgetText.t(lang, "Uygulamayı bir kez aç", "Open the app once")
                } else {
                    WidgetText.t(
                        lang,
                        "Bugün için rutin yok — bir rutin ekle",
                        "No routines today — add one"
                    )
                }
            )

            for (i in ROWS.indices) {
                val row = ROWS[i]
                val routine = today.getOrNull(i)
                if (routine == null) {
                    views.setViewVisibility(row.root, View.GONE)
                    continue
                }
                views.setViewVisibility(row.root, View.VISIBLE)
                // Yapıldıysa dolu accent daire + içinde onay; yapılmadıysa boş
                // halka. Onay işareti ImageView'ın **alfası** ile gizlenir —
                // saydam renk filtresi işe YARAMAZ: setColorFilter(int)
                // SRC_ATOP kullanır ve alfası 0 olan kaynak hedefi olduğu gibi
                // bırakır, yani ikon yine görünürdü.
                views.setInt(
                    row.check,
                    "setBackgroundResource",
                    if (routine.done) pal.checkFillRes else pal.checkRingRes
                )
                views.setInt(row.check, "setImageAlpha", if (routine.done) 255 else 0)
                if (routine.done) {
                    views.setInt(row.check, "setColorFilter", pal.onAccent)
                }
                views.setTextViewText(row.title, routine.title)
                views.setTextColor(row.title, if (routine.done) pal.text2 else pal.text)
                views.setInt(
                    row.title,
                    "setPaintFlags",
                    if (routine.done) PaintFlags.STRIKE else PaintFlags.PLAIN
                )
                views.setTextViewText(row.time, routine.time)
                views.setTextColor(row.time, if (routine.done) pal.text2 else pal.text3)
                views.setOnClickPendingIntent(
                    row.root,
                    WidgetIntents.toggleRoutine(context, routine.id, routine.done)
                )
            }

            val overflow = today.size - ROWS.size
            views.setViewVisibility(
                R.id.rt_more,
                if (overflow > 0) View.VISIBLE else View.GONE
            )
            if (overflow > 0) {
                views.setTextColor(R.id.rt_more_text, pal.text3)
                views.setInt(R.id.rt_more_icon, "setColorFilter", pal.text3)
                views.setTextViewText(
                    R.id.rt_more_text,
                    WidgetText.t(lang, "+$overflow rutin daha", "+$overflow more")
                )
            }

            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private data class Row(val root: Int, val check: Int, val title: Int, val time: Int)

    companion object {
        const val ACTION_TOGGLE = "com.bronzecloud.notsdaleit.ROUTINE_TOGGLE"
        const val EXTRA_ROUTINE_ID = "routineId"
        const val EXTRA_DONE = "done"

        private val ROWS = listOf(
            Row(R.id.rt_row_0, R.id.rt_check_0, R.id.rt_title_0, R.id.rt_time_0),
            Row(R.id.rt_row_1, R.id.rt_check_1, R.id.rt_title_1, R.id.rt_time_1),
            Row(R.id.rt_row_2, R.id.rt_check_2, R.id.rt_title_2, R.id.rt_time_2),
        )
    }
}
