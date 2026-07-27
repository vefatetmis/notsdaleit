package com.bronzecloud.notsdaleit

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

/**
 * 4×1 kısayol şeridi: **yeni not · çizim · ara · takvim**.
 *
 * Dört ayrı dokunuş alanı; her biri uygulamayı ilgili eylemle açar. "Çizim" de
 * yeni not açar ama kalem aracıyla — kâğıt hemen çizime hazır gelir.
 *
 * Tasarım (Widgetlar.dc.html): widget yüzeyi üstünde dört sütun; her sütunda
 * yuvarlak köşeli **accent çipi** içinde çizgi ikon, altında etiket; sütunlar
 * ince dikey ayraçlarla bölünür.
 */
class ShortcutsWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val data = WidgetStore.data(context)
        val pal = WidgetPalette.of(data.dark)
        val lang = data.lang

        val slots = listOf(
            Slot(
                R.id.sc_0, R.id.sc_0_chip, R.id.sc_0_icon, R.id.sc_0_label,
                WidgetIntents.NEW_NOTE, WidgetText.t(lang, "Yeni not", "New note")
            ),
            Slot(
                R.id.sc_1, R.id.sc_1_chip, R.id.sc_1_icon, R.id.sc_1_label,
                WidgetIntents.NEW_DRAWING, WidgetText.t(lang, "Çizim", "Draw")
            ),
            Slot(
                R.id.sc_2, R.id.sc_2_chip, R.id.sc_2_icon, R.id.sc_2_label,
                WidgetIntents.SEARCH, WidgetText.t(lang, "Ara", "Search")
            ),
            Slot(
                R.id.sc_3, R.id.sc_3_chip, R.id.sc_3_icon, R.id.sc_3_label,
                WidgetIntents.CALENDAR, WidgetText.t(lang, "Takvim", "Calendar")
            ),
        )

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_shortcuts)
            views.setInt(R.id.sc_card, "setBackgroundResource", pal.surfaceRes)

            for (divider in DIVIDERS) {
                views.setInt(divider, "setBackgroundColor", pal.divider)
            }

            slots.forEachIndexed { index, slot ->
                views.setInt(slot.chip, "setBackgroundResource", pal.chipRes)
                views.setInt(slot.icon, "setColorFilter", pal.accent)
                views.setTextColor(slot.label, pal.text)
                views.setTextViewText(slot.label, slot.text)
                views.setOnClickPendingIntent(
                    slot.root,
                    WidgetIntents.launch(
                        context,
                        slot.action,
                        WidgetIntents.REQ_SHORTCUT_BASE + index
                    )
                )
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private data class Slot(
        val root: Int,
        val chip: Int,
        val icon: Int,
        val label: Int,
        val action: String,
        val text: String,
    )

    companion object {
        private val DIVIDERS = intArrayOf(R.id.sc_div_0, R.id.sc_div_1, R.id.sc_div_2)
    }
}
