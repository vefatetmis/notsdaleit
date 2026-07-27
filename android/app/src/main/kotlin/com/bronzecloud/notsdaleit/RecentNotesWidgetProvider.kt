package com.bronzecloud.notsdaleit

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.view.View
import android.widget.RemoteViews

/**
 * 4×2 **Son notlar** widget'ı: en son düzenlenen dört belge, **2×2 ızgarada**.
 *
 * Tasarım (Widgetlar.dc.html, dördüncü kart): başlıkta logo işareti + "Son
 * notlar" + accent dolgulu `+`; her iç kartta tür göstergesi (not → çizgi
 * belge ikonu, PDF → **"PDF" rozeti**), başlık ve "klasör · zaman".
 *
 * Karta dokun → belge açılır (not → editör, PDF → görüntüleyici).
 *
 * **Kilitli notlar bu listeye girmez** — başlıkları ana ekranda görünmesin
 * diye Dart tarafında elenir (bkz. `features/widget/widget_data.dart`).
 */
class RecentNotesWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val data = WidgetStore.data(context)
        val pal = WidgetPalette.of(data.dark)
        val lang = data.lang
        val notes = data.notes

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_recent_notes)

            views.setInt(R.id.rc_card, "setBackgroundResource", pal.surfaceRes)
            views.setInt(R.id.rc_logo, "setBackgroundResource", pal.logoRes)
            views.setInt(R.id.rc_logo_icon, "setColorFilter", pal.onLogo)
            views.setInt(R.id.rc_add, "setBackgroundResource", pal.addBtnRes)
            views.setInt(R.id.rc_add_icon, "setColorFilter", pal.onAccent)
            views.setTextColor(R.id.rc_header_title, pal.text)
            views.setTextColor(R.id.rc_empty, pal.text2)
            views.setTextViewText(
                R.id.rc_header_title,
                WidgetText.t(lang, "Son notlar", "Recent notes")
            )

            views.setOnClickPendingIntent(
                R.id.rc_add,
                WidgetIntents.launch(
                    context,
                    WidgetIntents.NEW_NOTE,
                    WidgetIntents.REQ_RECENT_NEW
                )
            )
            views.setOnClickPendingIntent(
                R.id.rc_header_title,
                WidgetIntents.launch(
                    context,
                    WidgetIntents.LIBRARY,
                    WidgetIntents.REQ_RECENT_HEADER
                )
            )

            val empty = notes.isEmpty()
            views.setViewVisibility(R.id.rc_empty, if (empty) View.VISIBLE else View.GONE)
            views.setViewVisibility(R.id.rc_grid_top, if (empty) View.GONE else View.VISIBLE)
            views.setViewVisibility(
                R.id.rc_grid_bottom,
                if (notes.size > 2) View.VISIBLE else View.GONE
            )
            views.setTextViewText(
                R.id.rc_empty,
                if (!data.hasData) {
                    WidgetText.t(lang, "Uygulamayı bir kez aç", "Open the app once")
                } else {
                    WidgetText.t(
                        lang,
                        "Henüz belge yok — ilk notunu oluştur",
                        "No documents yet — create your first note"
                    )
                }
            )

            for (i in CARDS.indices) {
                val card = CARDS[i]
                val note = notes.getOrNull(i)
                if (note == null) {
                    // Alt satırdaki boş kart tamamen gizlenirse ızgara bozulur;
                    // görünmez bırakılır ki kalan kart yarım genişlikte kalsın.
                    views.setViewVisibility(card.root, View.INVISIBLE)
                    continue
                }
                views.setViewVisibility(card.root, View.VISIBLE)
                views.setInt(card.root, "setBackgroundResource", pal.innerRes)

                // PDF'ler ikon yerine rozetle ayrılır (tasarım kararı).
                views.setViewVisibility(card.icon, if (note.isPdf) View.GONE else View.VISIBLE)
                views.setViewVisibility(card.badge, if (note.isPdf) View.VISIBLE else View.GONE)
                views.setInt(card.icon, "setColorFilter", pal.text2)
                views.setInt(card.badge, "setBackgroundResource", pal.badgeRes)
                views.setTextColor(card.badge, pal.accent)

                views.setTextViewText(
                    card.title,
                    note.title.ifBlank {
                        WidgetText.t(lang, "Adsız not", "Untitled note")
                    }
                )
                views.setTextColor(card.title, pal.text)

                val meta = listOf(note.folder, note.time)
                    .filter { it.isNotBlank() }
                    .joinToString(" · ")
                views.setTextViewText(card.meta, meta)
                views.setTextColor(card.meta, pal.text2)

                views.setOnClickPendingIntent(
                    card.root,
                    WidgetIntents.launch(
                        context,
                        WidgetIntents.openNote(note.id),
                        WidgetIntents.REQ_NOTE_BASE + note.id
                    )
                )
            }

            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private data class Card(
        val root: Int,
        val icon: Int,
        val badge: Int,
        val title: Int,
        val meta: Int,
    )

    companion object {
        private val CARDS = listOf(
            Card(R.id.rc_card_0, R.id.rc_icon_0, R.id.rc_badge_0, R.id.rc_title_0, R.id.rc_meta_0),
            Card(R.id.rc_card_1, R.id.rc_icon_1, R.id.rc_badge_1, R.id.rc_title_1, R.id.rc_meta_1),
            Card(R.id.rc_card_2, R.id.rc_icon_2, R.id.rc_badge_2, R.id.rc_title_2, R.id.rc_meta_2),
            Card(R.id.rc_card_3, R.id.rc_icon_3, R.id.rc_badge_3, R.id.rc_title_3, R.id.rc_meta_3),
        )
    }
}
