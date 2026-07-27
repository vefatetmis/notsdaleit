package com.bronzecloud.notsdaleit

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

/**
 * 2×1 ana ekran widget'ı: **Yeni not**.
 *
 * Dokununca uygulamayı açıp doğrudan boş bir A4 not oluşturur (araya şablon
 * diyaloğu girmez — widget'ın amacı hız).
 *
 * Tasarım (Widgetlar.dc.html): accent **dolgulu** kart; içinde yarı saydam
 * daire + artı, yanında "Yeni not" / "notsdaleit" iki satırı.
 */
class QuickNoteWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val data = WidgetStore.data(context)
        val pal = WidgetPalette.of(data.dark)

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_quick_note)

            views.setInt(R.id.qn_card, "setBackgroundResource", pal.accentCardRes)
            views.setInt(R.id.qn_circle, "setBackgroundResource", pal.circleRes)
            views.setInt(R.id.qn_icon, "setColorFilter", pal.onAccent)
            views.setTextColor(R.id.qn_label, pal.onAccent)
            views.setTextColor(R.id.qn_sub, pal.onAccent2)
            views.setTextViewText(
                R.id.qn_label,
                WidgetText.t(data.lang, "Yeni not", "New note")
            )

            views.setOnClickPendingIntent(
                R.id.qn_card,
                WidgetIntents.launch(
                    context,
                    WidgetIntents.NEW_NOTE,
                    WidgetIntents.REQ_QUICK_NOTE
                )
            )
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
