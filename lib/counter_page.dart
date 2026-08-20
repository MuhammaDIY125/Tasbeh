import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'counter_cubit.dart';
import 'l10n/app_localizations.dart';
import 'settings_drawer.dart';
import 'system_bars.dart';
import 'vibration_cubit.dart';

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  static const numberStyle = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const padding = 8.0;

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  @override
  void initState() {
    super.initState();
    _enterCountingMode();
  }

  @override
  void dispose() {
    _exitCountingMode();
    super.dispose();
  }

  /// Прячет статус-бар и удерживает экран включённым: зикр можно читать долго,
  /// не касаясь экрана.
  void _enterCountingMode() {
    SystemBars.hideStatusBar();
    WakelockPlus.enable();
  }

  void _exitCountingMode() {
    SystemBars.showStatusBar();
    WakelockPlus.disable();
  }

  @override
  Widget build(BuildContext context) {
    final counterCubit = context.read<CounterCubit>();
    final vibrationCubit = context.read<VibrationCubit>();
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      drawer: const SettingsDrawer(),
      // Счёт идёт частыми касаниями по всему экрану: свайп от края открывал бы
      // настройки случайно, поэтому оставляем только кнопку.
      drawerEnableOpenDragGesture: false,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => counterCubit.increment(
            vibrate: vibrationCubit.state.isEnabled,
            intensity: vibrationCubit.state.intensity,
          ),
          child: Stack(
            children: [
              Positioned(
                left: CounterPage.padding,
                top: CounterPage.padding,
                // `Builder` даёт контекст ниже `Scaffold` — только из него
                // виден `ScaffoldState` с панелью настроек.
                child: Builder(
                  builder: (context) => IconButton(
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    icon: const Icon(Icons.menu_rounded),
                  ),
                ),
              ),
              Positioned(
                right: CounterPage.padding,
                top: CounterPage.padding,
                child: Column(
                  children: [
                    IconButton(
                      onPressed: () => _resetCounter(context, counterCubit, t),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                    IconButton(
                      onPressed: counterCubit.decrement,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                  ],
                ),
              ),
              Center(
                child: BlocBuilder<CounterCubit, int>(
                  builder: (context, counter) {
                    return Text(
                      '$counter',
                      textAlign: TextAlign.center,
                      style: CounterPage.numberStyle,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetCounter(
    BuildContext context,
    CounterCubit cubit,
    AppLocalizations t,
  ) {
    if (cubit.state == 0) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(t.resetConfirmationMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.cancel),
            ),
            TextButton(
              onPressed: () {
                cubit.reset();
                Navigator.pop(context);
              },
              child: Text(
                t.reset,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }
}
