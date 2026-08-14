import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'counter_cubit.dart';
import 'l10n/app_localizations.dart';
import 'settings_page.dart';
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
    _hideStatusBar();
  }

  @override
  void dispose() {
    _showSystemBars();
    super.dispose();
  }

  /// Прячет верхнюю системную панель, оставляя нижнюю навигацию доступной.
  void _hideStatusBar() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: const [SystemUiOverlay.bottom],
    );
  }

  void _showSystemBars() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<void> _openSettings(BuildContext context) async {
    _showSystemBars();
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
    if (mounted) _hideStatusBar();
  }

  @override
  Widget build(BuildContext context) {
    final counterCubit = context.read<CounterCubit>();
    final vibrationCubit = context.read<VibrationCubit>();
    final t = AppLocalizations.of(context)!;

    return Scaffold(
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
                child: IconButton(
                  onPressed: () => _openSettings(context),
                  icon: const Icon(Icons.menu_rounded),
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
          title: Text(t.resetConfirmationTitle),
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
