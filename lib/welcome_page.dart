import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_icon.dart';
import 'app_theme.dart';
import 'counter_page.dart';
import 'l10n/app_localizations.dart';
import 'palette_picker.dart';
import 'theme_cubit.dart';

/// Экран первого запуска: выбор темы.
///
/// Показывается, пока выбор не подтверждён кнопкой, — в том числе тем, кто
/// обновился со старой версии: иначе о темах они узнали бы, только случайно
/// заглянув в настройки.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        // Прокрутка нужна только при крупном системном шрифте, когда сетка и
        // кнопка перестают помещаться; в остальных случаях превью счётчика
        // просто занимает всё свободное место над ними.
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.popupPadding),
                child: Column(
                  children: [
                    // Экран сам перекрашивается в выбранную тему, а цифры
                    // набраны стилем счётчика — вместе это и есть главный
                    // экран, каким он будет. 33 — как на иконке приложения.
                    Expanded(
                      child: Center(
                        child: Text(
                          '33',
                          style: CounterPage.numberStyle.copyWith(
                            color: theme.iconTheme.color,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      t.chooseThemeTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t.chooseThemeHint,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 40),
                    const PalettePicker(),
                    const SizedBox(height: 40),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        textStyle: theme.textTheme.titleMedium,
                      ),
                      onPressed: () => _start(context),
                      child: Text(t.start),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Подтверждает выбор и ставит значок приложения в цвет выбранной темы.
  void _start(BuildContext context) {
    final themeCubit = context.read<ThemeCubit>()..confirmChoice();
    AppIcon.match(themeCubit.state.palette);
  }
}
