import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

import 'app_theme.dart';
import 'l10n/app_localizations.dart';

/// Ключ для доступа к `Navigator` из мест, где нет своего `context`
/// (например, из сервиса обновлений). Передаётся в `MaterialApp`.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Сервис обновления приложения через нативный механизм Google Play
/// (Android In-App Updates).
///
/// Используется гибкий (flexible) сценарий: Google Play сам проверяет наличие
/// обновления и показывает своё окно. Обновление скачивается в фоне, после чего
/// пользователю предлагается перезапустить приложение для установки.
class InAppUpdateService {
  const InAppUpdateService._();

  /// Проверяет наличие обновления и при необходимости запускает гибкое
  /// обновление средствами Google Play.
  ///
  /// Работает только на Android — In-App Updates это API Google Play.
  static Future<void> checkForUpdate() async {
    // В debug-сборках приложение не установлено через Google Play, и
    // Play Services может подолгу висеть в ожидании ответа (особенно на
    // эмуляторах без залогиненного Play Store) — проверка тут бессмысленна.
    if (kDebugMode || !Platform.isAndroid) return;

    try {
      final AppUpdateInfo info = await InAppUpdate.checkForUpdate();

      // Обновление уже скачано в прошлом запуске — осталось только
      // перезапустить приложение.
      if (info.installStatus == InstallStatus.downloaded) {
        _promptRestart();
        return;
      }

      final bool isUpdateAvailable =
          info.updateAvailability == UpdateAvailability.updateAvailable;
      if (!isUpdateAvailable || !info.flexibleUpdateAllowed) return;

      // Запускаем загрузку обновления в фоне. Future завершится, когда
      // Google Play докачает обновление, при этом приложением можно
      // продолжать пользоваться.
      final AppUpdateResult result = await InAppUpdate.startFlexibleUpdate();

      if (result == AppUpdateResult.success) {
        _promptRestart();
      }
    } catch (e) {
      // Сбой проверки обновлений не должен влиять на работу приложения.
      log(
        'InAppUpdateService: update check failed: $e',
        name: 'InAppUpdateService',
      );
    }
  }

  /// Показывает диалог с предложением перезапустить приложение и применить
  /// уже загруженное обновление.
  static void _promptRestart() {
    final NavigatorState? navigator = navigatorKey.currentState;
    if (navigator == null) return;

    final BuildContext context = navigator.context;
    final AppLocalizations? t = AppLocalizations.of(context);
    if (t == null) return;

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        contentPadding: AppTheme.dialogContentPadding,
        content: Text(t.updateReady),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _completeUpdate();
            },
            child: Text(t.updateRestart),
          ),
        ],
      ),
    );
  }

  /// Применяет уже загруженное обновление и перезапускает приложение.
  ///
  /// Google Play может отказать в установке (например, приложение поставлено
  /// не из Play), поэтому ошибка гасится так же, как и при проверке обновлений.
  static Future<void> _completeUpdate() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      log(
        'InAppUpdateService: complete update failed: $e',
        name: 'InAppUpdateService',
      );
    }
  }
}
