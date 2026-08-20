// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsTitle => 'Settings';

  @override
  String get vibration => 'Vibration';

  @override
  String get vibrationIntensity => 'Vibration intensity';

  @override
  String get level => 'Level';

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
  String get reminderTime => 'Reminder time';

  @override
  String get notificationTitle => 'Time for tasbeh';

  @override
  String get notificationBody => 'Take a moment for dhikr';

  @override
  String get notificationChannelName => 'Daily reminder';

  @override
  String get notificationChannelDescription => 'Tasbeh reminder at the time you chose';

  @override
  String get updateReady => 'Update downloaded';

  @override
  String get updateRestart => 'Restart';
}
