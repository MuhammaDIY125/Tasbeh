import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

import 'l10n/app_localizations.dart';

/// Ключ для доступа к `ScaffoldMessenger` из мест, где нет своего `context`
/// (например, из сервиса обновлений). Передаётся в `MaterialApp`.
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

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
    if (!Platform.isAndroid) return;

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

  /// Показывает уведомление с предложением перезапустить приложение и применить
  /// уже загруженное обновление.
  static void _promptRestart() {
    final ScaffoldMessengerState? messenger = scaffoldMessengerKey.currentState;
    final BuildContext? context = scaffoldMessengerKey.currentContext;
    if (messenger == null || context == null) return;

    final AppLocalizations? t = AppLocalizations.of(context);
    if (t == null) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(t.updateReady),
        duration: const Duration(days: 1),
        action: SnackBarAction(
          label: t.updateRestart,
          onPressed: InAppUpdate.completeFlexibleUpdate,
        ),
      ),
    );
  }
}
