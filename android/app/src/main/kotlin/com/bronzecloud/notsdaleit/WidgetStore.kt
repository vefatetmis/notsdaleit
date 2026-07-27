package com.bronzecloud.notsdaleit

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import java.util.Locale

/**
 * Ana ekran widget'larının verisi.
 *
 * **Neden `home_widget` paketi yok:** tek ihtiyacımız Flutter'dan gelen bir JSON
 * dizesini saklamak. Paket eklemek yeni bir Kotlin sürüm bağımlılığı demekti;
 * eklentiler burada 1.9.25'e sabit (bkz. CLAUDE.md). Onun yerine Dart tarafı
 * `notsdaleit/widget` kanalından `setWidgetData` ile JSON yollar, burada saklanır.
 *
 * Üç şey tutulur:
 * - **data**: Flutter'ın ürettiği anlık görüntü (rutinler, son belgeler, tema, dil).
 * - **overrides**: kullanıcı widget'tan bir rutini işaretlediğinde anında
 *   görünsün diye tutulan yerel üstünlükler ("id:gün" → yapıldı mı).
 * - **pending**: aynı işaretlerin veritabanına yazılmayı bekleyen kuyruğu;
 *   uygulama açılınca Dart `takePendingRoutineToggles` ile alıp uygular.
 */
object WidgetStore {

    private const val PREFS = "nd_widget"
    private const val KEY_DATA = "data"
    private const val KEY_OVERRIDES = "overrides"
    private const val KEY_PENDING = "pending"

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    // ── Flutter'dan gelen anlık görüntü ──────────────────────────────────

    fun saveData(context: Context, json: String) {
        val p = prefs(context)
        val editor = p.edit().putString(KEY_DATA, json)
        // Bekleyen işaret yoksa Dart'ın verisi artık doğrunun kaynağıdır;
        // yerel üstünlükler temizlenir. Kuyruk doluysa (tam bu sırada yeni bir
        // dokunuş geldiyse) üstünlükler durur, yoksa ekran geri sekerdi.
        if (pendingArray(p).length() == 0) editor.remove(KEY_OVERRIDES)
        editor.apply()
    }

    fun data(context: Context): WidgetData = parse(prefs(context).getString(KEY_DATA, null))

    // ── Rutin işaretleme (widget'tan dokunma) ────────────────────────────

    /** Widget'tan bir rutin işaretlendi/kaldırıldı: hem görünüm hem kuyruk. */
    fun toggleRoutine(context: Context, routineId: Int, currentlyDone: Boolean) {
        val p = prefs(context)
        val day = today()
        val done = !currentlyDone

        val overrides = JSONObject(p.getString(KEY_OVERRIDES, "{}") ?: "{}")
        overrides.put("$routineId:$day", done)

        // Kuyrukta aynı rutin+gün varsa yenisiyle değiştir (kararlı son durum).
        val pending = pendingArray(p)
        val next = JSONArray()
        for (i in 0 until pending.length()) {
            val o = pending.optJSONObject(i) ?: continue
            if (o.optInt("id") == routineId && o.optString("day") == day) continue
            next.put(o)
        }
        next.put(JSONObject().put("id", routineId).put("day", day).put("done", done))

        p.edit()
            .putString(KEY_OVERRIDES, overrides.toString())
            .putString(KEY_PENDING, next.toString())
            .apply()
    }

    /** Kuyruğu Dart'a devreder ve boşaltır (uygulama açılışında/dönüşünde). */
    fun takePending(context: Context): String {
        val p = prefs(context)
        val pending = p.getString(KEY_PENDING, "[]") ?: "[]"
        p.edit().remove(KEY_PENDING).apply()
        return pending
    }

    private fun pendingArray(p: android.content.SharedPreferences): JSONArray =
        try {
            JSONArray(p.getString(KEY_PENDING, "[]") ?: "[]")
        } catch (_: Exception) {
            JSONArray()
        }

    private fun overrides(context: Context): JSONObject = try {
        JSONObject(prefs(context).getString(KEY_OVERRIDES, "{}") ?: "{}")
    } catch (_: Exception) {
        JSONObject()
    }

    /**
     * Bugün planlı rutinler — yerel üstünlükler uygulanmış hâlde.
     *
     * Gün maskesi burada değerlendirilir (Dart'ta değil): böylece gece yarısı
     * `DATE_CHANGED` yayını geldiğinde uygulama hiç açılmadan da liste ve
     * işaretler doğru güne göre yeniden çizilir.
     */
    fun routinesForToday(context: Context, data: WidgetData): List<WidgetRoutine> {
        val day = today()
        val index = weekdayIndex()
        val ov = overrides(context)
        return data.routines
            .filter { it.days.length > index && it.days[index] == '1' }
            .map { r ->
                val key = "${r.id}:$day"
                val done = if (ov.has(key)) ov.optBoolean(key) else (r.doneDay == day)
                r.copy(done = done)
            }
    }

    // ── Gün yardımcıları ─────────────────────────────────────────────────

    /** Bugün, `yyyy-MM-dd` — Dart tarafıyla aynı biçim. */
    fun today(): String {
        val c = Calendar.getInstance()
        return String.format(
            Locale.US, "%04d-%02d-%02d",
            c.get(Calendar.YEAR), c.get(Calendar.MONTH) + 1, c.get(Calendar.DAY_OF_MONTH)
        )
    }

    /** Pazartesi = 0 … Pazar = 6 (Routines.days maskesiyle aynı sıra). */
    private fun weekdayIndex(): Int {
        // Calendar: Pazar=1 … Cumartesi=7
        val c = Calendar.getInstance().get(Calendar.DAY_OF_WEEK)
        return (c + 5) % 7
    }

    // ── Ayrıştırma ───────────────────────────────────────────────────────

    private fun parse(json: String?): WidgetData {
        if (json.isNullOrEmpty()) return WidgetData()
        return try {
            val o = JSONObject(json)
            val routines = mutableListOf<WidgetRoutine>()
            val ra = o.optJSONArray("routines") ?: JSONArray()
            for (i in 0 until ra.length()) {
                val r = ra.optJSONObject(i) ?: continue
                routines.add(
                    WidgetRoutine(
                        id = r.optInt("id"),
                        title = r.optString("title"),
                        days = r.optString("days", "1111111"),
                        doneDay = r.optString("doneDay").ifEmpty { null },
                        streak = r.optInt("streak"),
                        time = r.optString("time"),
                    )
                )
            }
            val notes = mutableListOf<WidgetNote>()
            val na = o.optJSONArray("notes") ?: JSONArray()
            for (i in 0 until na.length()) {
                val n = na.optJSONObject(i) ?: continue
                notes.add(
                    WidgetNote(
                        id = n.optInt("id"),
                        title = n.optString("title"),
                        preview = n.optString("preview"),
                        time = n.optString("time"),
                        folder = n.optString("folder"),
                        isPdf = n.optBoolean("pdf"),
                    )
                )
            }
            WidgetData(
                dark = o.optBoolean("dark"),
                lang = o.optString("lang", "tr"),
                streaks = o.optBoolean("streaks", true),
                hasData = true,
                routines = routines,
                notes = notes,
            )
        } catch (_: Exception) {
            WidgetData()
        }
    }

    // ── Yenileme ─────────────────────────────────────────────────────────

    /** Dört widget'ı da yeniden çizer (veri değiştiğinde çağrılır). */
    fun refreshAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context) ?: return
        val providers = listOf(
            QuickNoteWidgetProvider::class.java,
            ShortcutsWidgetProvider::class.java,
            RoutinesWidgetProvider::class.java,
            RecentNotesWidgetProvider::class.java,
        )
        for (cls in providers) {
            val ids = manager.getAppWidgetIds(ComponentName(context, cls))
            if (ids == null || ids.isEmpty()) continue
            val intent = android.content.Intent(context, cls).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
            context.sendBroadcast(intent)
        }
    }
}

data class WidgetData(
    val dark: Boolean = false,
    val lang: String = "tr",
    val streaks: Boolean = true,
    /** Uygulama hiç açılmadıysa false — widget'lar "boş" hâlini gösterir. */
    val hasData: Boolean = false,
    val routines: List<WidgetRoutine> = emptyList(),
    val notes: List<WidgetNote> = emptyList(),
)

data class WidgetRoutine(
    val id: Int,
    val title: String,
    /** Pzt..Paz için 7 karakterlik '1'/'0' maskesi. */
    val days: String,
    /** En son işaretlendiği gün (`yyyy-MM-dd`) — bugünse yapılmış sayılır. */
    val doneDay: String?,
    val streak: Int,
    /** Hatırlatıcı saati ("07:00") — yoksa boş. Tasarımda satırın sağında. */
    val time: String = "",
    val done: Boolean = false,
)

data class WidgetNote(
    val id: Int,
    val title: String,
    val preview: String,
    val time: String,
    /** Klasör adı — tasarımda "klasör · zaman" satırında. */
    val folder: String,
    val isPdf: Boolean,
)
