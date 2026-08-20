package com.tasbeh.app

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

    // Систему нельзя удержать в полноэкранном режиме навсегда: клавиатура,
    // шторка уведомлений и возврат из фона возвращают статус-бар.
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus && isStatusBarHidden) setStatusBarHidden(true)
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
