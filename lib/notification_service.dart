import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Сервис для управления локальными push-уведомлениями.
///
/// Планирует ежедневное напоминание в выбранное пользователем время.
/// Используется как синглтон через [instance].
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _dailyReminderId = 1;
  static const String _channelId = 'tasbeh_daily_reminder';
  static const String _channelName = 'Daily Tasbeh Reminder';

  /// Инициализирует плагин. Вызывается один раз при запуске приложения.
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: settings);
    log('NotificationService: initialized', name: 'NotificationService');
  }

  /// Запрашивает разрешение на отправку уведомлений.
  ///
  /// Возвращает `true`, если разрешение получено.
  Future<bool> requestPermission() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    bool granted = false;

    if (androidPlugin != null) {
      granted = await androidPlugin.requestNotificationsPermission() ?? false;
    } else if (iosPlugin != null) {
      granted =
          await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    log(
      'NotificationService: permission granted=$granted',
      name: 'NotificationService',
    );
    return granted;
  }

  /// Планирует ежедневное уведомление в указанное [time].
  ///
  /// Принимает [title] и [body] — текст уведомления.
  Future<void> scheduleDailyReminder({
    required TimeOfDay time,
    required String title,
    required String body,
  }) async {
    await _plugin.cancelAll();

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Если выбранное время уже прошло сегодня — начинаем со следующего дня.
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.periodicallyShowWithDuration(
      id: _dailyReminderId,
      title: title,
      body: body,
      repeatDurationInterval: const Duration(days: 1),
      notificationDetails: details,
      payload: 'daily_tasbeh',
    );

    log(
      'NotificationService: scheduled daily at ${time.hour}:${time.minute}',
      name: 'NotificationService',
    );
  }

  /// Отменяет ежедневное уведомление.
  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(id: _dailyReminderId);
    log('NotificationService: cancelled', name: 'NotificationService');
  }
}
