import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';

import 'theme_cubit.dart';

/// Значок приложения на рабочем столе в цветах темы.
///
/// Звать по окончании выбора темы, а не на каждое нажатие в сетке: iOS при
/// смене значка сразу показывает своё уведомление, и перебор тем подряд
/// обернулся бы чередой всплывающих окон. Android сам откладывает смену до
/// ухода приложения в фон.
abstract final class AppIcon {
  static const _channel = MethodChannel('com.tasbeh.app/app_icon');

  /// Ставит значок темы [palette]. Если он уже стоит, ничего не происходит.
  static Future<void> match(ThemePalette palette) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    // Значок — оформление: сбой канала не должен мешать пользоваться темой.
    try {
      await _channel.invokeMethod<void>('setIcon', palette.name);
    } on PlatformException catch (e) {
      log('AppIcon.match failed: $e', name: 'AppIcon');
    } on MissingPluginException catch (e) {
      log('AppIcon.match unavailable: $e', name: 'AppIcon');
    }
  }
}
