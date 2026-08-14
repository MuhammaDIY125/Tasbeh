// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Tasbeh';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get darkTheme => 'Темная тема';

  @override
  String get sound => 'Звук';

  @override
  String get vibration => 'Вибрация';

  @override
  String get resetSettings => 'Сбросить настройки';

  @override
  String get counter => 'Счётчик';

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
  String get dailyReminderTime => 'Время напоминания';

  @override
  String get dailyReminderSubtitle => 'Напоминание о таcбехах';

  @override
  String get reminderTimePickerTitle => 'Время напоминания';

  @override
  String get notificationTitle => 'Время таcбеха 📿';

  @override
  String get notificationBody => 'Не забудьте совершить ежедневный тасбех!';

  @override
  String get vibrationIntensity => 'Сила вибрации';

  @override
  String get level => 'Уровень';

  @override
  String get updateReady => 'Обновление загружено';

  @override
  String get updateRestart => 'Перезапустить';
}
