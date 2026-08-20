import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibration/vibration.dart';

import 'l10n/app_localizations.dart';
import 'locale_cubit.dart';
import 'notification_cubit.dart';
import 'notification_service.dart';
import 'vibration_cubit.dart';

/// Настройки в виде выезжающей слева панели.
///
/// Панель живёт внутри `Scaffold` главного экрана, поэтому открытие настроек
/// не создаёт новый маршрут и не трогает режим системных панелей — счётчик
/// под ней остаётся на месте.
///
/// Настроек мало, и все они разные, поэтому список плоский: рамки и подписи
/// групп добавляли бы структуру там, где её нечего структурировать.
class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Drawer(
      // Стандартные 304 dp оставляют полосу поверх счётчика; панель почти во
      // всю ширину читается как отдельный экран. Верхний предел нужен планшетам,
      // где доля экрана растянула бы список настроек через всю ширину.
      width: (MediaQuery.sizeOf(context).width * 0.86).clamp(304.0, 400.0),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Text(
                t.settingsTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const _LanguageSection(),
            const _VibrationSection(),
            const _ReminderSection(),
          ],
        ),
      ),
    );
  }
}

/// Текущее значение настройки справа от названия.
///
/// Намеренно тише самого названия: значение подсказывает состояние, но не
/// должно спорить за внимание.
class _ValueLabel extends StatelessWidget {
  final String value;

  const _ValueLabel(this.value);

  @override
  Widget build(BuildContext context) => Text(
    value,
    style: TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontSize: 16,
    ),
  );
}

/// Выбор языка интерфейса.
class _LanguageSection extends StatelessWidget {
  const _LanguageSection();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return BlocBuilder<LocaleCubit, String>(
      builder: (context, code) {
        return ListTile(
          title: Text(t.language),
          trailing: _ValueLabel(_languageName(code)),
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
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.language, style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                for (final code in const ['uz', 'ru', 'en'])
                  _LanguageTile(
                    name: _languageName(code),
                    isSelected: currentCode == code,
                    onTap: () {
                      context.read<LocaleCubit>().setLocale(code);
                      Navigator.pop(sheetContext);
                    },
                  ),
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

    return BlocBuilder<VibrationCubit, VibrationState>(
      builder: (context, vibration) {
        return Column(
          children: [
            SwitchListTile(
              title: Text(t.vibration),
              value: vibration.isEnabled,
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.vibrationIntensity),
              _ValueLabel('${t.level} ${((intensity / 255) * 9).round() + 1}'),
            ],
          ),
          Slider(
            value: intensity.toDouble(),
            min: 1,
            max: 255,
            divisions: 9,
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

    return BlocBuilder<NotificationCubit, TimeOfDay?>(
      builder: (context, time) {
        return Column(
          children: [
            SwitchListTile(
              title: Text(t.dailyReminder),
              value: time != null,
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
                title: Text(t.reminderTime),
                trailing: _ValueLabel(time.format(context)),
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
      helpText: t.reminderTime,
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
      title: Text(name, style: const TextStyle(fontSize: 16)),
      trailing: isSelected
          ? Icon(Icons.check, size: 20, color: theme.colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
