import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'l10n/app_localizations.dart';
import 'locale_cubit.dart';
import 'notification_cubit.dart';
import 'notification_service.dart';
import 'vibration_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.settingsTitle),
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          BlocBuilder<VibrationCubit, bool>(
            builder: (context, vibration) {
              return SwitchListTile(
                title: Text(t.vibration),
                value: vibration,
                activeThumbColor: colorScheme.primary,
                onChanged: (_) => context.read<VibrationCubit>().toggle(),
              );
            },
          ),
          BlocBuilder<NotificationCubit, TimeOfDay?>(
            builder: (context, time) {
              return SwitchListTile(
                title: Text(t.dailyReminder),
                subtitle: Text(
                  time != null ? time.format(context) : t.dailyReminderSubtitle,
                  style: time != null
                      ? TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        )
                      : null,
                ),
                value: time != null,
                activeThumbColor: colorScheme.primary,
                onChanged: (value) async {
                  if (!value) {
                    context.read<NotificationCubit>().disable();
                    await NotificationService.instance.cancelDailyReminder();
                  } else {
                    final granted = await NotificationService.instance
                        .requestPermission();
                    if (!granted && context.mounted) return;

                    if (!context.mounted) return;
                    final selectedTime = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 20, minute: 0),
                      helpText: t.reminderTimePickerTitle,
                    );

                    if (selectedTime != null && context.mounted) {
                      context.read<NotificationCubit>().setTime(selectedTime);
                      await NotificationService.instance.scheduleDailyReminder(
                        time: selectedTime,
                        title: t.notificationTitle,
                        body: t.notificationBody,
                      );
                    }
                  }
                },
              );
            },
          ),
          BlocBuilder<LocaleCubit, String>(
            builder: (context, code) {
              return ListTile(
                title: Text(t.language),
                trailing: Text(
                  _getLanguageName(code),
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                onTap: () => _showLanguagePicker(context, code),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'uz':
        return 'O‘zbek';
      case 'ru':
        return 'Русский';
      case 'en':
        return 'English';
      default:
        return 'English';
    }
  }

  void _showLanguagePicker(BuildContext context, String currentCode) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.language,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _LanguageTile(
                  name: 'O\'zbek',
                  isSelected: currentCode == 'uz',
                  onTap: () => _selectLanguage(context, 'uz'),
                ),
                _LanguageTile(
                  name: 'Русский',
                  isSelected: currentCode == 'ru',
                  onTap: () => _selectLanguage(context, 'ru'),
                ),
                _LanguageTile(
                  name: 'English',
                  isSelected: currentCode == 'en',
                  onTap: () => _selectLanguage(context, 'en'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _selectLanguage(BuildContext context, String code) {
    context.read<LocaleCubit>().setLocale(code);
    Navigator.pop(context);
  }
}

class _LanguageTile extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? theme.colorScheme.primary : null,
          fontSize: 16,
        ),
      ),
      trailing: isSelected
          ? Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}
