import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'app_icon.dart';
import 'app_theme.dart';
import 'counter_cubit.dart';
import 'counter_page.dart';
import 'in_app_update_service.dart';
import 'l10n/app_localizations.dart';
import 'locale_cubit.dart';
import 'notification_cubit.dart';
import 'notification_service.dart';
import 'system_bars.dart';
import 'theme_cubit.dart';
import 'vibration_cubit.dart';
import 'welcome_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory(dir.path),
  );

  // Тема нужна раньше приложения: по яркости её фона красятся значки
  // системных панелей, и выставленные до первого кадра они не перекрашиваются
  // у пользователя на глазах.
  final themeCubit = ThemeCubit();
  await SystemBars.applyEdgeToEdge(themeCubit.state.palette.brightness);

  // Сбой инициализации уведомлений не должен мешать запуску: без runApp
  // пользователь видит только чёрный экран.
  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    log('main: notification init failed: $e', name: 'main');
  }

  runApp(MainApp(themeCubit: themeCubit));
}

/// Планирует ежедневное напоминание на языке `localeCode` либо отменяет его,
/// если оно выключено.
///
/// Локализации берутся напрямую у делегата: слушатели живут выше
/// `MaterialApp`, поэтому `AppLocalizations.of(context)` здесь вернул бы null.
Future<void> _syncReminder({
  required String localeCode,
  required NotificationState notification,
}) async {
  if (!notification.isEnabled) {
    await NotificationService.instance.cancelDailyReminder();
    return;
  }

  final t = await AppLocalizations.delegate.load(Locale(localeCode));
  await NotificationService.instance.scheduleDailyReminder(
    time: notification.time,
    title: t.notificationTitle,
    body: t.notificationBody,
    channelName: t.notificationChannelName,
    channelDescription: t.notificationChannelDescription,
  );
}

class MainApp extends StatefulWidget {
  final ThemeCubit themeCubit;

  const MainApp({super.key, required this.themeCubit});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();

    // Проверяем обновление после первого кадра: к этому моменту
    // `navigatorKey` уже привязан к дереву и сможет показать диалог.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      InAppUpdateService.checkForUpdate();
    });

    // Значок сверяется с темой и при запуске: прошлая смена могла не дойти
    // до системы — например, если приложение закрыли, не свернув.
    final themeState = widget.themeCubit.state;
    if (themeState.isChosen) AppIcon.match(themeState.palette);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => CounterCubit()),
        BlocProvider(create: (context) => LocaleCubit()),
        BlocProvider(create: (context) => VibrationCubit()),
        BlocProvider(create: (context) => NotificationCubit()),
        BlocProvider.value(value: widget.themeCubit),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<NotificationCubit, NotificationState>(
            listener: (context, notification) => _syncReminder(
              localeCode: context.read<LocaleCubit>().state,
              notification: notification,
            ),
          ),
          // Тексты уведомления фиксируются в момент планирования, поэтому
          // при смене языка напоминание нужно пересоздать заново.
          BlocListener<LocaleCubit, String>(
            listener: (context, localeCode) => _syncReminder(
              localeCode: localeCode,
              notification: context.read<NotificationCubit>().state,
            ),
          ),
          BlocListener<ThemeCubit, ThemeState>(
            listenWhen: (previous, current) =>
                previous.palette.brightness != current.palette.brightness,
            listener: (context, themeState) =>
                SystemBars.matchBackground(themeState.palette.brightness),
          ),
        ],
        child: BlocBuilder<LocaleCubit, String>(
          builder: (context, localeCode) {
            return BlocBuilder<ThemeCubit, ThemeState>(
              builder: (context, themeState) {
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  title: 'Tasbeh',
                  navigatorKey: navigatorKey,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  locale: Locale(localeCode),
                  theme: AppTheme.of(themeState.palette),
                  builder: (context, child) =>
                      AnnotatedRegion<SystemUiOverlayStyle>(
                        value: SystemBars.overlayStyleFor(
                          themeState.palette.brightness,
                        ),
                        child: child!,
                      ),
                  // Экран выбора темы не маршрут, а подмена главного
                  // экрана: после «Начать» назад к нему вернуться нельзя, и
                  // стеку навигации нечего было бы помнить.
                  //
                  // Ключи обязательны: переход по умолчанию ключует обёртку
                  // по `child.key`, и у двух экранов без ключей обёртки
                  // совпадали — уходящий экран пропадал сразу, и между
                  // экранами мелькал чёрный кадр.
                  home: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: themeState.isChosen
                        ? const CounterPage(key: ValueKey(CounterPage))
                        : const WelcomePage(key: ValueKey(WelcomePage)),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
