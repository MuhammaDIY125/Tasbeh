import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'counter_cubit.dart';
import 'counter_page.dart';
import 'l10n/app_localizations.dart';
import 'locale_cubit.dart';
import 'notification_cubit.dart';
import 'notification_service.dart';
import 'vibration_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory(dir.path),
  );

  await NotificationService.instance.initialize();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

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
            listener: (context, time) async {
              if (time != null) {
                final t = AppLocalizations.of(context);
                if (t != null) {
                  await NotificationService.instance.scheduleDailyReminder(
                    time: time,
                    title: t.notificationTitle,
                    body: t.notificationBody,
                  );
                }
              }
            },
          ),
        ],
        child: BlocBuilder<LocaleCubit, String>(
          builder: (context, localeCode) {
            return MaterialApp(
              title: 'Tasbeh',
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: Locale(localeCode),
              darkTheme: ThemeData(
                brightness: Brightness.dark,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.teal,
                  brightness: Brightness.dark,
                ),
                scaffoldBackgroundColor: Colors.black,
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.black,
                  surfaceTintColor: Colors.black,
                ),
                iconTheme: const IconThemeData(size: 32, color: Colors.white),
              ),
              themeMode: ThemeMode.dark,
              home: const CounterPage(),
            );
          },
        ),
      ),
    );
  }
}
