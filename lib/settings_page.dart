import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibration/vibration.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(t.settingsTitle),
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        children: const [
          _LanguageSection(),
          _VibrationSection(),
          _ReminderSection(),
        ],
      ),
    );
  }
}

/// Выбор языка интерфейса.
class _LanguageSection extends StatelessWidget {
  const _LanguageSection();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<LocaleCubit, String>(
      builder: (context, code) {
        return ListTile(
          title: Text(t.language),
          trailing: Text(
            _languageName(code),
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          onTap: () => _showLanguagePicker(context, code),
        );
      },
    );
  }

  static String _languageName(String code) => switch (code) {
    'uz' => 'O‘zbek',
    'ru' => 'Русский',
    _ => 'English',
  };

  void _showLanguagePicker(BuildContext context, String currentCode) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
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
                for (final code in const ['uz', 'ru', 'en'])
                  _LanguageTile(
                    name: _languageName(code),
                    isSelected: currentCode == code,
                    onTap: () {
                      context.read<LocaleCubit>().setLocale(code);
                      Navigator.pop(sheetContext);
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Включение вибрации и настройка её силы.
class _VibrationSection extends StatelessWidget {
  const _VibrationSection();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<VibrationCubit, VibrationState>(
      builder: (context, vibration) {
        return Column(
          children: [
            SwitchListTile(
              title: Text(t.vibration),
              value: vibration.isEnabled,
              activeThumbColor: colorScheme.primary,
              onChanged: (_) => context.read<VibrationCubit>().toggle(),
            ),
            if (vibration.isEnabled)
              _IntensitySlider(intensity: vibration.intensity),
          ],
        );
      },
    );
  }
}

class _IntensitySlider extends StatelessWidget {
  final int intensity;

  const _IntensitySlider({required this.intensity});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.vibrationIntensity),
              Text(
                '${t.level} ${((intensity / 255) * 9).round() + 1}',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: intensity.toDouble(),
            min: 1,
            max: 255,
            divisions: 9,
            activeColor: colorScheme.primary,
            onChanged: (value) {
              final selected = value.toInt();
              context.read<VibrationCubit>().setIntensity(selected);
              // Даем пользователю почувствовать выбранную силу
              Vibration.vibrate(amplitude: selected, duration: 30);
            },
          ),
        ],
      ),
    );
  }
}

/// Ежедневное напоминание: включение и время.
class _ReminderSection extends StatelessWidget {
  const _ReminderSection();

  static const _defaultTime = TimeOfDay(hour: 20, minute: 0);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<NotificationCubit, TimeOfDay?>(
      builder: (context, time) {
        return Column(
          children: [
            SwitchListTile(
              title: Text(t.dailyReminder),
              value: time != null,
              activeThumbColor: colorScheme.primary,
              onChanged: (enabled) {
                if (enabled) {
                  _pickTime(context);
                } else {
                  context.read<NotificationCubit>().disable();
                }
              },
            ),
            if (time != null)
              ListTile(
                title: Text(t.dailyReminderTime),
                trailing: Text(
                  time.format(context),
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                onTap: () => _pickTime(context, initialTime: time),
              ),
          ],
        );
      },
    );
  }

  /// Запрашивает разрешение и сохраняет выбранное время.
  ///
  /// Само уведомление планирует слушатель `NotificationCubit` в `MainApp` —
  /// так время и язык напоминания всегда пересобираются из одного места.
  Future<void> _pickTime(BuildContext context, {TimeOfDay? initialTime}) async {
    final t = AppLocalizations.of(context)!;
    final notificationCubit = context.read<NotificationCubit>();

    final granted = await NotificationService.instance.requestPermission();
    if (!granted || !context.mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime ?? _defaultTime,
      helpText: t.reminderTimePickerTitle,
    );
    if (selectedTime == null) return;

    notificationCubit.setTime(selectedTime);
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
