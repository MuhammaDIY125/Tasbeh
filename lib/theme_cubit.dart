import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

/// Цветовая тема: фон экрана и акцент элементов управления.
///
/// Цифры, иконки и текст берут цвет не у темы, а у яркости её фона: белые на
/// тёмных фонах, почти чёрные на светлых.
///
/// Тёмные фоны глубокие и приглушённые, светлые — не чисто белые, а мягкие:
/// внутри каждой группы одна светлота и насыщенность в OKLCH, разный только
/// оттенок. Так ни одна тема не спорит со счётчиком и не выделяется среди
/// соседей. Акцент — тот же оттенок, но на другом краю светлоты: переключатель
/// должен читаться на своём фоне, а не теряться в нём.
enum ThemePalette {
  /// Исходная тема приложения: чёрный фон под OLED и бирюзовый акцент.
  black(background: Colors.black, accent: Color(0xFF5E9B90)),
  graphite(background: Color(0xFF22262A), accent: Color(0xFFA6B3C1)),
  midnight(background: Color(0xFF172338), accent: Color(0xFF93ABD8)),
  emerald(background: Color(0xFF112A1D), accent: Color(0xFF84B99C)),
  pomegranate(background: Color(0xFF39191B), accent: Color(0xFFD69899)),
  white(background: Color(0xFFF5F5F2), accent: Color(0xFF3E746B)),
  sand(background: Color(0xFFEFE5D4), accent: Color(0xFF7F5A3C)),
  sage(background: Color(0xFFDBE4D9), accent: Color(0xFF4A6D51));

  final Color background;
  final Color accent;

  const ThemePalette({required this.background, required this.accent});

  /// Яркость фона — от неё зависят цвет текста, значки системных панелей и
  /// то, чем выделяются края всплывающих окон.
  Brightness get brightness => ThemeData.estimateBrightnessForColor(background);
}

/// Выбранная тема и то, выбирал ли её пользователь сам.
class ThemeState {
  final ThemePalette palette;

  /// Пока выбора не было, при запуске вместо счётчика открывается экран
  /// выбора темы.
  final bool isChosen;

  const ThemeState({required this.palette, required this.isChosen});

  ThemeState copyWith({ThemePalette? palette, bool? isChosen}) => ThemeState(
    palette: palette ?? this.palette,
    isChosen: isChosen ?? this.isChosen,
  );
}

/// Хранит и персистирует тему между сессиями.
class ThemeCubit extends HydratedCubit<ThemeState> {
  ThemeCubit()
    : super(const ThemeState(palette: ThemePalette.black, isChosen: false));

  void setPalette(ThemePalette palette) =>
      emit(state.copyWith(palette: palette));

  /// Закрывает экран первого выбора: дальше тема меняется в настройках.
  void confirmChoice() => emit(state.copyWith(isChosen: true));

  /// Незнакомое имя темы — например, убранной в новой версии — откатывает
  /// к чёрной, но сам факт выбора сохраняет: экран выбора второй раз не
  /// всплывёт.
  @override
  ThemeState? fromJson(Map<String, dynamic> json) => ThemeState(
    palette:
        ThemePalette.values.asNameMap()[json['palette']] ?? ThemePalette.black,
    isChosen: json['isChosen'] as bool? ?? false,
  );

  @override
  Map<String, dynamic>? toJson(ThemeState state) => {
    'palette': state.palette.name,
    'isChosen': state.isChosen,
  };
}
