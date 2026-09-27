package com.tasbeh.app

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ActivityInfo
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.util.Log

/**
 * Значок приложения на рабочем столе в цветах темы.
 *
 * Основной значок — у самой `MainActivity`, значки цветных тем — у
 * `activity-alias` в манифесте, и включена всегда одна из этих точек входа.
 * Переключение откладывается до ухода приложения в фон: смена
 * включённой точки входа заставляет лаунчер пересобрать значки, а некоторые
 * прошивки при этом перезапускают приложение — посреди зикра этого быть не
 * должно. Заодно при переборе тем подряд лаунчер обновляется один раз, а не на
 * каждую.
 *
 * В отладочных сборках (debug и profile) значок всегда основной: `flutter run`
 * открывает приложение через `MainActivity` и не смог бы запустить его, пока
 * она выключена ради значка другой темы. Смену значка проверять в release.
 */
class LauncherIcon(private val context: Context) {
    private var pendingEntry: String? = null

    /** Запоминает значок темы [palette] — имени из `ThemePalette` во Flutter. */
    fun request(palette: String) {
        pendingEntry = if (palette == DEFAULT_PALETTE || isDebuggable) {
            DEFAULT_ENTRY
        } else {
            DEFAULT_ENTRY + palette.replaceFirstChar { it.uppercase() }
        }
    }

    private val isDebuggable
        get() = context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0

    /** Включает запрошенный значок и выключает остальные. */
    fun applyPending() {
        val entry = pendingEntry ?: return
        pendingEntry = null

        val launcherEntries = context.packageManager.queryIntentActivities(
            Intent(Intent.ACTION_MAIN)
                .addCategory(Intent.CATEGORY_LAUNCHER)
                .setPackage(context.packageName),
            PackageManager.MATCH_DISABLED_COMPONENTS,
        ).map { it.activityInfo }

        val target = launcherEntries.firstOrNull { it.name.substringAfterLast('.') == entry }
        if (target == null) {
            Log.w(TAG, "No launcher entry $entry")
            return
        }

        // Сначала включаем новый значок, потом гасим прежний: иначе на миг у
        // приложения не остаётся ни одной точки входа с рабочего стола.
        setEnabled(target, true)
        launcherEntries.filter { it.name != target.name }.forEach { setEnabled(it, false) }
    }

    private fun setEnabled(entry: ActivityInfo, enabled: Boolean) {
        val packageManager = context.packageManager
        val component = ComponentName(entry.packageName, entry.name)

        // Пока состояние не меняли, действует `android:enabled` из манифеста.
        val isEnabled = when (packageManager.getComponentEnabledSetting(component)) {
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> true
            PackageManager.COMPONENT_ENABLED_STATE_DEFAULT -> entry.enabled
            else -> false
        }
        if (isEnabled == enabled) return

        packageManager.setComponentEnabledSetting(
            component,
            if (enabled) {
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            } else {
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            },
            PackageManager.DONT_KILL_APP,
        )
    }

    private companion object {
        const val TAG = "LauncherIcon"

        /** Тема, чей значок — основной, у самой `.MainActivity`. */
        const val DEFAULT_PALETTE = "black"
        const val DEFAULT_ENTRY = "MainActivity"
    }
}
