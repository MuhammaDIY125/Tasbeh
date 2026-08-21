package com.tasbeh.app

import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Прячет статус-бар через `WindowInsetsController`.
 *
 * `SystemChrome.setEnabledSystemUIMode` из Flutter опирается на устаревшие
 * `View.SYSTEM_UI_FLAG_*`, а Android 15 (API 35) и новее их игнорирует:
 * приложения с targetSdk 35+ всегда рисуются edge-to-edge.
 */
class MainActivity : FlutterActivity() {
    private var isStatusBarHidden = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        drawEdgeToEdge()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hideStatusBar" -> {
                        setStatusBarHidden(true)
                        result.success(null)
                    }

                    "showStatusBar" -> {
                        setStatusBarHidden(false)
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    // Получая фокус, окно теряет оформление системных панелей: их цвет
    // возвращается к чёрному из темы, а полноэкранный режим — к обычному.
    // Фокус приходит последним в череде onResume/onPostResume, поэтому
    // восстанавливаем всё именно здесь.
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (!hasFocus) return

        drawEdgeToEdge()

        // Систему нельзя удержать в полноэкранном режиме навсегда: клавиатура,
        // шторка уведомлений и возврат из фона возвращают статус-бар.
        if (isStatusBarHidden) setStatusBarHidden(true)
    }

    /**
     * Растягивает окно под системные панели и делает сами панели прозрачными.
     *
     * Отступы после этого — забота содержимого: их держат `SafeArea` внутри
     * экрана счёта и панели настроек. Панель должна уходить за статус-бар
     * целиком, поэтому сама она отступа не получает.
     */
    private fun drawEdgeToEdge() {
        WindowCompat.setDecorFitsSystemWindows(window, false)

        // Цвета и флаг фона панелей на API 35+ уже не действуют: там панели
        // всегда прозрачные, а окно и так edge-to-edge.
        @Suppress("DEPRECATION")
        window.apply {
            // Без этого флага систему рисует панели непрозрачными, и содержимое
            // за ними не видно, как бы далеко окно ни растянулось.
            addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)
            statusBarColor = Color.TRANSPARENT
            navigationBarColor = Color.TRANSPARENT

            // Иначе система подкладывает под панели свою полупрозрачную заливку,
            // и края экрана выглядят светлее чёрного фона приложения.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                isStatusBarContrastEnforced = false
                isNavigationBarContrastEnforced = false
            }
        }

        // Приложение всегда тёмное, значки панелей поверх него должны быть
        // светлыми — независимо от темы системы.
        WindowCompat.getInsetsController(window, window.decorView).apply {
            isAppearanceLightStatusBars = false
            isAppearanceLightNavigationBars = false
        }
    }

    private fun setStatusBarHidden(hidden: Boolean) {
        isStatusBarHidden = hidden

        val controller = WindowCompat.getInsetsController(window, window.decorView)
        if (!hidden) {
            controller.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_DEFAULT
            controller.show(WindowInsetsCompat.Type.statusBars())
            return
        }

        // Свайп сверху показывает панель лишь на время: система убирает её сама
        // после паузы или касания экрана. Такая панель рисуется поверх контента
        // и не меняет insets, поэтому разметка приложения не дёргается.
        controller.systemBarsBehavior =
            WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        controller.hide(WindowInsetsCompat.Type.statusBars())
    }

    private companion object {
        const val CHANNEL = "com.tasbeh.app/system_bars"
    }
}
