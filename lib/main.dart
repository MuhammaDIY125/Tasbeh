import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'app_theme.dart';
import 'counter_cubit.dart';
import 'counter_page.dart';
import 'in_app_update_service.dart';
import 'l10n/app_localizations.dart';
import 'locale_cubit.dart';
import 'notification_cubit.dart';
import 'notification_service.dart';
import 'system_bars.dart';
import 'vibration_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemBars.applyEdgeToEdge();

  final dir = await getApplicationDocumentsDirectory();

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory(dir.path),
  );

  // Сбой инициализации уведомлений не должен мешать запуску: без runApp
  // пользователь видит только чёрный экран.
  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    log('main: notification init failed: $e', name: 'main');
  }

  runApp(const MainApp());
}

/// Планирует ежедневное напоминание на языке `localeCode` либо отменяет его,
/// если время не задано.
///
/// Локализации берутся напрямую у делегата: слушатели живут выше
/// `MaterialApp`, поэтому `AppLocalizations.of(context)` здесь вернул бы null.
Future<void> _syncReminder({
  required String localeCode,
  required TimeOfDay? time,
}) async {
  if (time == null) {
    await NotificationService.instance.cancelDailyReminder();
    return;
  }

  final t = await AppLocalizations.delegate.load(Locale(localeCode));
  await NotificationService.instance.scheduleDailyReminder(
    time: time,
    title: t.notificationTitle,
    body: t.notificationBody,
    channelName: t.notificationChannelName,
    channelDescription: t.notificationChannelDescription,
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

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
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => CounterCubit()),
        BlocProvider(create: (context) => LocaleCubit()),
        BlocProvider(create: (context) => VibrationCubit()),
        BlocProvider(create: (context) => NotificationCubit()),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<NotificationCubit, TimeOfDay?>(
            listener: (context, time) => _syncReminder(
              localeCode: context.read<LocaleCubit>().state,
              time: time,
            ),
          ),
          // Тексты уведомления фиксируются в момент планирования, поэтому
          // при смене языка напоминание нужно пересоздать заново.
          BlocListener<LocaleCubit, String>(
            listener: (context, localeCode) => _syncReminder(
              localeCode: localeCode,
              time: context.read<NotificationCubit>().state,
            ),
          ),
        ],
        child: BlocBuilder<LocaleCubit, String>(
          builder: (context, localeCode) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Tasbeh',
              navigatorKey: navigatorKey,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: Locale(localeCode),
              darkTheme: AppTheme.dark,
              themeMode: ThemeMode.dark,
              home: const CounterPage(),
            );
          },
        ),
      ),
    );
  }
}
