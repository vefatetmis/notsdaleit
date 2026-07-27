package com.bronzecloud.notsdaleit

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/**
 * Ana ekran widget'ı: "Yeni not".
 *
 * Dokununca uygulamayı [MainActivity.ACTION_NEW_NOTE] eylemiyle açar; Flutter
 * tarafı bu eylemi görüp doğrudan boş bir not oluşturur (araya şablon diyaloğu
 * girmez — widget'ın amacı hız).
 *
 * **Neden `home_widget` paketi yok:** widget durağan (dinamik veri
 * göstermiyor), tek ihtiyacı bir PendingIntent. Paket eklemek yeni bir Kotlin
 * sürüm bağımlılığı demekti; eklentiler burada 1.9.25'e sabitli (bkz.
 * CLAUDE.md). İleride widget'ta gerçek veri (bugünün görevleri gibi)
 * göstermek istenirse paket o zaman değerlendirilir.
 */
class QuickNoteWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            val intent = Intent(context, MainActivity::class.java).apply {
                action = MainActivity.ACTION_NEW_NOTE
                // singleTask activity: uygulama açıksa yeni kopya açılmaz,
                // onNewIntent ile mevcut kopyaya düşer.
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val views = RemoteViews(context.packageName, R.layout.widget_quick_note)
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
