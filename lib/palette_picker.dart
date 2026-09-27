import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'l10n/app_localizations.dart';
import 'theme_cubit.dart';

/// Название темы на языке интерфейса.
extension ThemePaletteName on ThemePalette {
  String localizedName(AppLocalizations t) => switch (this) {
    ThemePalette.black => t.themeBlack,
    ThemePalette.graphite => t.themeGraphite,
    ThemePalette.midnight => t.themeMidnight,
    ThemePalette.emerald => t.themeEmerald,
    ThemePalette.pomegranate => t.themePomegranate,
    ThemePalette.white => t.themeWhite,
    ThemePalette.sand => t.themeSand,
    ThemePalette.sage => t.themeSage,
  };
}

/// Кружки тем.
///
/// Выбор применяется сразу, без подтверждения: тема перекрашивает весь экран,
/// и сравнивать темы удобнее на нём самом, чем на кружках.
///
/// Названий на экране нет — тему узнают по цвету, а подписи превращали бы
/// сетку в список. Название у каждого кружка есть только для экранного
/// диктора.
class PalettePicker extends StatelessWidget {
  const PalettePicker({super.key});

  static const double _swatchSize = 52;
  static const double _spacing = 18;

  /// Ширина ровно под четыре кружка: восемь тем складываются в два ровных
  /// ряда, а не в длинную ленту на широком экране.
  static const double _maxWidth = _swatchSize * 4 + _spacing * 3;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      buildWhen: (previous, current) => previous.palette != current.palette,
      builder: (context, themeState) {
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: Wrap(
            spacing: _spacing,
            runSpacing: _spacing,
            children: [
              for (final palette in ThemePalette.values)
                _SelectableSwatch(
                  palette: palette,
                  size: _swatchSize,
                  isSelected: palette == themeState.palette,
                  onTap: () => context.read<ThemeCubit>().setPalette(palette),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Кружок темы в сетке выбора.
///
/// Выбор отмечен кольцом через зазор, цвета текста темы: белое пропало бы на
/// белой теме, а чёрное — на чёрной.
class _SelectableSwatch extends StatelessWidget {
  final ThemePalette palette;
  final double size;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectableSwatch({
    required this.palette,
    required this.size,
    required this.isSelected,
    required this.onTap,
  });

  /// Толщина кольца выбора и зазор между ним и кружком.
  static const double _ringWidth = 2;
  static const double _ringGap = 4;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final ink = Theme.of(context).colorScheme.onSurface;

    return Semantics(
      button: true,
      selected: isSelected,
      label: palette.localizedName(t),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          padding: const EdgeInsets.all(_ringGap),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? ink : Colors.transparent,
              width: _ringWidth,
            ),
          ),
          child: PaletteSwatch(
            palette: palette,
            size: size - 2 * (_ringWidth + _ringGap),
          ),
        ),
      ),
    );
  }
}

/// Тема в миниатюре: кружок её фона с точкой акцента в центре.
///
/// Кружок стоит на фоне текущей темы, и у совпадающей с ней заливка сливается
/// с экраном. Его держит тонкий контур цвета текста темы — он виден на любом
/// фоне.
class PaletteSwatch extends StatelessWidget {
  final ThemePalette palette;
  final double size;

  const PaletteSwatch({super.key, required this.palette, required this.size});

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.background,
        border: Border.all(color: ink.withValues(alpha: 0.25)),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: palette.accent,
        ),
        child: SizedBox.square(dimension: size * 0.3),
      ),
    );
  }
}
