import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vibration/vibration.dart';

import 'app_theme.dart';
import 'edge_glow.dart';
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
/// групп добавляли бы структуру там, где её нечего структурировать. Исключение
/// — "Поделиться" внизу: это не настройка, а действие, и `Divider` отделяет
/// его от них, чтобы не читалось как ещё один переключатель.
class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return EdgeGlow(
      borderRadius: const BorderRadius.horizontal(
        right: Radius.circular(AppTheme.drawerCornerRadius),
      ),
      child: Drawer(
        // Стандартные 304 dp оставляют полосу поверх счётчика; панель почти во
        // всю ширину читается как отдельный экран. Верхний предел нужен
        // планшетам, где доля экрана растянула бы список настроек через всю
        // ширину.
        width: (MediaQuery.sizeOf(context).width * 0.86).clamp(304.0, 400.0),
        child: SafeArea(
          // Версия прибита к низу панели, а не к концу списка: список короткий,
          // и в конце текста она читалась бы как ещё один пункт настроек.
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 12),
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
                    const Divider(),
                    const _ShareSection(),
                  ],
                ),
              ),
              const _AppVersion(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Версия приложения по центру нижнего края панели.
///
/// Номер берётся у платформы, а не из константы в коде: так он не разъезжается
/// с `version:` в pubspec при выпуске новой сборки.
class _AppVersion extends StatelessWidget {
  const _AppVersion();

  /// Читается один раз за запуск: панель открывают часто, а версия за это
  /// время не меняется.
  static final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: FutureBuilder<PackageInfo>(
        future: _packageInfo,
        builder: (context, snapshot) {
          final version = snapshot.data?.version;

          // Пока версия не пришла, место под неё держит пустой текст: иначе
          // список настроек дёргался бы вниз в первый кадр после открытия.
          return Text(
            version == null ? '' : 'v$version',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          );
        },
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
            padding: const EdgeInsets.only(bottom: AppTheme.popupPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Заголовок отбит от краёв так же, как пункты ниже: сам по
                // себе он стоит по центру, но длинное название языка на узком
                // экране иначе упёрлось бы в край листа.
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.popupPadding,
                  ),
                  child: Text(t.language, style: theme.textTheme.titleMedium),
                ),
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, notification) {
        return Column(
          children: [
            SwitchListTile(
              title: Text(t.dailyReminder),
              value: notification.isEnabled,
              onChanged: (enabled) {
                if (enabled) {
                  _pickTime(context, initialTime: notification.time);
                } else {
                  context.read<NotificationCubit>().disable();
                }
              },
            ),
            if (notification.isEnabled)
              ListTile(
                title: Text(t.reminderTime),
                trailing: _ValueLabel(notification.time.format(context)),
                onTap: () => _pickTime(context, initialTime: notification.time),
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
  Future<void> _pickTime(
    BuildContext context, {
    required TimeOfDay initialTime,
  }) async {
    final t = AppLocalizations.of(context)!;
    final notificationCubit = context.read<NotificationCubit>();

    final granted = await NotificationService.instance.requestPermission();
    if (!granted || !context.mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: t.reminderTime,
    );
    if (selectedTime == null) return;

    notificationCubit.setTime(selectedTime);
  }
}

/// Пункт "Поделиться приложением" — отправляет ссылку на Google Play.
class _ShareSection extends StatelessWidget {
  const _ShareSection();

  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.tasbeh.app';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return ListTile(title: Text(t.shareApp), onTap: () => _share(context));
  }

  // iPad требует `sharePositionOrigin` для листа "Поделиться" — без него
  // вызов падает с исключением. Центр экрана — универсальный якорь, раз у
  // пункта настроек нет своей кнопки, от которой лист мог бы выезжать.
  Future<void> _share(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox;

    await SharePlus.instance.share(
      ShareParams(
        text: 'Tasbeh\n\n$_playStoreUrl',
        sharePositionOrigin: Rect.fromCenter(
          center: box.size.center(Offset.zero),
          width: 1,
          height: 1,
        ),
      ),
    );
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.popupPadding,
      ),
      title: Text(name, style: const TextStyle(fontSize: 16)),
      trailing: isSelected
          ? Icon(Icons.check, size: 20, color: theme.colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
