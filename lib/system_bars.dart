import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';

/// Управляет видимостью статус-бара.
///
/// На Android идёт в нативный `WindowInsetsController`: приложения с
/// targetSdk 35+ всегда рисуются edge-to-edge, и система игнорирует
/// [SystemChrome.setEnabledSystemUIMode] с любым режимом, кроме
/// [SystemUiMode.edgeToEdge]. На остальных платформах хватает Flutter API.
abstract final class SystemBars {
  static const _channel = MethodChannel('com.tasbeh.app/system_bars');

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
