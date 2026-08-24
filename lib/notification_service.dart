import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Сервис для управления локальными push-уведомлениями.
class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _dailyReminderId = 1;

  /// Канал версионируется: Android не применяет изменения настроек
  /// (важность, звук, категория) к уже созданному каналу.
  static const _channelId = 'tasbeh_daily_reminder_v2';
  static const _legacyChannelId = 'tasbeh_daily_reminder';

  /// Силуэт логотипа для статус-бара: Android рисует small icon
  /// по альфа-каналу, поэтому непрозрачный логотип превращался
  /// в белый квадрат. Генерируется `tool/generate_notification_icon.py`.
  static const _statusBarIcon = 'ic_stat_tasbeh';

  /// Инициализирует плагин.
  Future<void> initialize() async {
    tz.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final timeZoneName = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      log(
        'NotificationService: timezone set to $timeZoneName',
        name: 'NotificationService',
      );
    } catch (e) {
      log(
        'NotificationService: failed to get timezone: $e',
        name: 'NotificationService',
      );
    }

    const androidSettings = AndroidInitializationSettings(
      '@drawable/$_statusBarIcon',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        log(
          'NotificationService: notification tapped with payload ${response.payload}',
          name: 'NotificationService',
        );
      },
    );
    await _removeLegacyChannel();

    log('NotificationService: initialized', name: 'NotificationService');
  }

  /// Удаляет канал прошлых версий, иначе система продолжит показывать
  /// уведомления с его старыми настройками.
  Future<void> _removeLegacyChannel() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.deleteNotificationChannel(channelId: _legacyChannelId);
  }

  /// Запрашивает разрешения.
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
      log(
        'NotificationService: android notification permission=$granted',
        name: 'NotificationService',
      );

      // Специальный запрос для точных алармов на Android 12+
      final hasExactAlarmPermission = await _canScheduleExactAlarms();
      if (!hasExactAlarmPermission) {
        log(
          'NotificationService: requesting exact alarms permission',
          name: 'NotificationService',
        );
        final exactGranted = await androidPlugin.requestExactAlarmsPermission();
        log(
          'NotificationService: exact alarms permission result=$exactGranted',
          name: 'NotificationService',
        );
      }
    } else if (iosPlugin != null) {
      granted =
          await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return granted;
  }

  Future<bool> _canScheduleExactAlarms() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) return true;
    return await androidPlugin.canScheduleExactNotifications() ?? false;
  }

  /// Создаёт (или обновляет название) канал уведомлений.
  ///
  /// Имя и описание видны в системных настройках, поэтому приходят
  /// из локализаций и обновляются при смене языка.
  Future<void> _ensureChannel({
    required String name,
    required String description,
  }) async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(
      AndroidNotificationChannel(
        _channelId,
        name,
        description: description,
        importance: Importance.high,
      ),
    );
  }

  /// Планирует ежедневное уведомление.
  Future<void> scheduleDailyReminder({
    required TimeOfDay time,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {
    try {
      await cancelDailyReminder();

      // Проверяем разрешение на точные алармы ПЕРЕД планированием
      final canSchedule = await _canScheduleExactAlarms();
      if (!canSchedule) {
        log(
          'NotificationService: no exact alarm permission, requesting...',
          name: 'NotificationService',
        );
        final androidPlugin = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        await androidPlugin?.requestExactAlarmsPermission();
        return;
      }

      await _ensureChannel(name: channelName, description: channelDescription);

      final androidDetails = AndroidNotificationDetails(
        _channelId,
        channelName,
        channelDescription: channelDescription,
        icon: _statusBarIcon,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        ticker: title,
        // Напоминание, а не будильник: без перехвата экрана.
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        styleInformation: BigTextStyleInformation(body, contentTitle: title),
        // Кружок под маленькой иконкой в шторке уведомлений: без этого
        // Android красит его акцентным цветом темы устройства.
        color: Colors.black,
        colorized: false,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final nextDate = _nextInstanceOfTime(time);
      log(
        'NotificationService: scheduling notification for original time: $time. Resulting date: $nextDate',
        name: 'NotificationService',
      );

      await _plugin.zonedSchedule(
        id: _dailyReminderId,
        title: title,
        body: body,
        scheduledDate: nextDate,
        notificationDetails: details,
        // exactAllowWhileIdle доставляет точно в срок и, в отличие от
        // alarmClock, не держит иконку будильника в статус-баре.
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'daily_tasbeh',
      );

      log(
        'NotificationService: SUCCESS. Scheduled daily at ${time.hour}:${time.minute}',
        name: 'NotificationService',
      );
    } catch (e, stack) {
      log(
        'NotificationService: ERROR scheduling notification: $e',
        name: 'NotificationService',
        error: e,
        stackTrace: stack,
      );
    }
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    log(
      'NotificationService: Current time (tz.local): $now',
      name: 'NotificationService',
    );
    log(
      'NotificationService: Target time (tz.local): $scheduledDate',
      name: 'NotificationService',
    );

    // Если дата в прошлом или слишком близко к настоящему (меньше 5 секунд)
    // даём запас, чтобы AlarmManager не отбросил уведомление как "прошедшее".
    final safeNow = now.add(const Duration(seconds: 5));
    if (scheduledDate.isBefore(safeNow)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
      log(
        'NotificationService: time is too close or in the past. Moved to: $scheduledDate',
        name: 'NotificationService',
      );
    }
    return scheduledDate;
  }

  /// Отменяет уведомление.
  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(id: _dailyReminderId);
    log('NotificationService: cancelled', name: 'NotificationService');
  }
}
