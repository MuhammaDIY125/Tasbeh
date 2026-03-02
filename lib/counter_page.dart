import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'counter_cubit.dart';
import 'l10n/app_localizations.dart';
import 'settings_page.dart';

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  static const numberStyle = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const padding = 8.0;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CounterCubit>();
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: cubit.increment,
          child: Stack(
            children: [
              Positioned(
                left: padding,
                top: padding,
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    );
                  },
                  icon: const Icon(Icons.menu_rounded),
                ),
              ),
              Positioned(
                right: padding,
                top: padding,
                child: Column(
                  children: [
                    IconButton(
                      onPressed: () => _resetCounter(context, cubit, t),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                    IconButton(
                      onPressed: cubit.decrement,
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
                      style: numberStyle,
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
