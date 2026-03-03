// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Tasbeh';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get darkTheme => 'Dark theme';

  @override
  String get sound => 'Sound';

  @override
  String get vibration => 'Vibration';

  @override
  String get resetSettings => 'Reset settings';

  @override
  String get counter => 'Counter';

  @override
  String get language => 'Language';

  @override
  String get resetConfirmationTitle => 'Reset counter?';

  @override
  String get resetConfirmationMessage => 'Are you sure you want to reset the counter to zero?';

  @override
  String get cancel => 'Cancel';

  @override
  String get reset => 'Reset';

  @override
  String get dailyReminder => 'Daily reminder';

  @override
  String get dailyReminderTime => 'Reminder time';

  @override
  String get dailyReminderSubtitle => 'Tasbeh reminder';

  @override
  String get reminderTimePickerTitle => 'Reminder time';

  @override
  String get notificationTitle => 'Tasbeh time 📿';

  @override
  String get notificationBody => 'Don\'t forget to do your daily tasbeh!';

  @override
  String get vibrationIntensity => 'Vibration intensity';

  @override
  String get level => 'Level';
}
