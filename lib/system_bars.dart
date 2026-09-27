import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';

/// Управляет системными панелями: режимом окна, цветом значков и видимостью
/// статус-бара.
///
/// Видимость на Android идёт в нативный `WindowInsetsController`: приложения с
/// targetSdk 35+ всегда рисуются edge-to-edge, и система игнорирует
/// [SystemChrome.setEnabledSystemUIMode] с любым режимом, кроме
/// [SystemUiMode.edgeToEdge]. На остальных платформах хватает Flutter API.
abstract final class SystemBars {
  static const _channel = MethodChannel('com.tasbeh.app/system_bars');

  /// Растягивает приложение под системные панели и делает сами панели
  /// прозрачными, со значками под цвет фона [background].
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
  static Future<void> applyEdgeToEdge(Brightness background) async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(overlayStyleFor(background));
    await matchBackground(background);
  }

  /// Стиль системных панелей под фон приложения [background]: панели
  /// прозрачные, значки на них контрастны фону.
  ///
  /// Держать его нужно через `AnnotatedRegion` над всем приложением, а не
  /// выставить один раз: `MaterialApp` на каждой перестройке сам задаёт стиль
  /// по яркости темы — с непрозрачной панелью навигации, а на светлой теме и
  /// с белыми кнопками на ней. Аннотацию фреймворк применяет после кадра, и
  /// она этот стиль перебивает.
  static SystemUiOverlayStyle overlayStyleFor(Brightness background) {
    final icons = background == Brightness.dark
        ? Brightness.light
        : Brightness.dark;

    return SystemUiOverlayStyle(
      statusBarColor: const Color(0x00000000),
      systemNavigationBarColor: const Color(0x00000000),
      systemNavigationBarDividerColor: const Color(0x00000000),

      // Android 10+ подкладывает под прозрачные панели свою полупрозрачную
      // заливку — ради контраста с кнопками навигации. На фоне приложения она
      // видна как полоса другого цвета вдоль края экрана.
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,

      statusBarIconBrightness: icons,
      systemNavigationBarIconBrightness: icons,
      // iOS описывает не значки, а фон под ними.
      statusBarBrightness: background,
    );
  }

  /// Сообщает `MainActivity` яркость фона приложения.
  ///
  /// Activity перекрашивает значки панелей заново при каждом возврате фокуса
  /// окну, и без этого после сворачивания значки на светлой теме снова стали
  /// бы белыми. На остальных платформах хватает [overlayStyleFor].
  static Future<void> matchBackground(Brightness background) async {
    if (!Platform.isAndroid) return;
    await _invokeAndroid(
      'setLightBackground',
      arguments: background == Brightness.light,
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

    await _invokeAndroid(androidMethod);
  }

  /// Системные панели — оформление, а не функциональность: сбой канала не
  /// должен ронять экран, который их настраивает.
  static Future<void> _invokeAndroid(String method, {Object? arguments}) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on PlatformException catch (e) {
      log('SystemBars.$method failed: $e', name: 'SystemBars');
    } on MissingPluginException catch (e) {
      log('SystemBars.$method unavailable: $e', name: 'SystemBars');
    }
  }
}
