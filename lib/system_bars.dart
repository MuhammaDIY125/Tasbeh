import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';

/// Управляет системными панелями: режимом окна и видимостью статус-бара.
///
/// Видимость на Android идёт в нативный `WindowInsetsController`: приложения с
/// targetSdk 35+ всегда рисуются edge-to-edge, и система игнорирует
/// [SystemChrome.setEnabledSystemUIMode] с любым режимом, кроме
/// [SystemUiMode.edgeToEdge]. На остальных платформах хватает Flutter API.
abstract final class SystemBars {
  static const _channel = MethodChannel('com.tasbeh.app/system_bars');

  /// Растягивает приложение под системные панели и делает сами панели
  /// прозрачными.
  ///
  /// Движок Flutter держит собственный режим системных панелей и переприменяет
  /// его на каждом `onPostResume`. Пока он не знает про edge-to-edge, он кладёт
  /// в окно свой набор устаревших `View.SYSTEM_UI_FLAG_*` поверх настройки
  /// `MainActivity`. Переключить режим можно только отсюда — и только в
  /// [SystemUiMode.edgeToEdge]: остальные режимы движок edge-to-edge не
  /// восстанавливает.
  ///
  /// Вызывать до `runApp`: стиль панелей уходит в систему после первого кадра,
  /// и заданный раньше он успевает к нему.
  static Future<void> applyEdgeToEdge() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0x00000000),
        systemNavigationBarColor: Color(0x00000000),
        systemNavigationBarDividerColor: Color(0x00000000),

        // Android 10+ подкладывает под прозрачные панели свою полупрозрачную
        // заливку — ради контраста с кнопками навигации. На чёрном фоне
        // приложения она видна как серая полоса вдоль края экрана.
        systemStatusBarContrastEnforced: false,
        systemNavigationBarContrastEnforced: false,

        // Приложение всегда тёмное, значки панелей поверх него должны быть
        // светлыми — независимо от темы системы.
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  /// Прячет статус-бар, оставляя нижнюю панель навигации на месте.
  static Future<void> hideStatusBar() => _apply(
    androidMethod: 'hideStatusBar',
    fallbackMode: SystemUiMode.manual,
    fallbackOverlays: const [SystemUiOverlay.bottom],
  );

  /// Возвращает системные панели — например, когда экран счёта закрывается.
  static Future<void> showStatusBar() => _apply(
    androidMethod: 'showStatusBar',
    fallbackMode: SystemUiMode.edgeToEdge,
  );

  static Future<void> _apply({
    required String androidMethod,
    required SystemUiMode fallbackMode,
    List<SystemUiOverlay>? fallbackOverlays,
  }) async {
    if (!Platform.isAndroid) {
      await SystemChrome.setEnabledSystemUIMode(
        fallbackMode,
        overlays: fallbackOverlays,
      );
      return;
    }

    // Статус-бар — оформление, а не функциональность: сбой канала не должен
    // ронять экран счёта.
    try {
      await _channel.invokeMethod<void>(androidMethod);
    } on PlatformException catch (e) {
      log('SystemBars.$androidMethod failed: $e', name: 'SystemBars');
    } on MissingPluginException catch (e) {
      log('SystemBars.$androidMethod unavailable: $e', name: 'SystemBars');
    }
  }
}
