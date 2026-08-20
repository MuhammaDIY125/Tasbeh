// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get vibration => 'Вибрация';

  @override
  String get vibrationIntensity => 'Сила вибрации';

  @override
  String get level => 'Уровень';

  @override
  String get language => 'Язык';

  @override
  String get resetConfirmationTitle => 'Сбросить счётчик?';

  @override
  String get resetConfirmationMessage => 'Вы уверены, что хотите обнулить счётчик?';

  @override
  String get cancel => 'Отмена';

  @override
  String get reset => 'Сброс';

  @override
  String get dailyReminder => 'Ежедневное напоминание';

  @override
  String get reminderTime => 'Время напоминания';

  @override
  String get notificationTitle => 'Время тасбиха';

  @override
  String get notificationBody => 'Не забудьте о зикре';

  @override
  String get notificationChannelName => 'Ежедневное напоминание';

  @override
  String get notificationChannelDescription => 'Напоминание о тасбехе в выбранное время';

  @override
  String get updateReady => 'Обновление загружено';

  @override
  String get updateRestart => 'Перезапустить';
}
