import 'package:flutter/material.dart';

import 'edge_glow.dart';

/// Тёмная тема приложения.
///
/// Экран счётчика полностью чёрный, поэтому surface-роли схемы переопределены
/// на нейтральный near-black: сгенерированные из бирюзового seed'а оттенки
/// уходят в зелень (`surfaceContainerLow` — `#161D1C`) и поверх чёрного фона
/// читаются как посторонняя серо-зелёная плита.
///
/// Сам акцент тоже приглушён: сгенерированная из seed'а бирюза `#82D5C8`
/// слишком звонкая для приложения, которое должно оставаться фоном для зикра,
/// а не притягивать взгляд.
class AppTheme {
  const AppTheme._();

  /// Фон карточек-групп: ровно настолько светлее чёрного, чтобы группа
  /// читалась как отдельный блок и при этом не спорила со счётчиком.
  static const Color surfaceCard = Color(0xFF0D0D0D);

  /// Разделители внутри поверхностей. Края поверхностей ею больше не
  /// обводятся: там [edgeGlow], потому что обводка делала всплывающее окно
  /// плоским вырезом в экране, а не листом поверх него.
  static const Color hairline = Color(0x1AFFFFFF);

  /// Скругление правого края панели настроек. Константа общая: по ней же
  /// строится свечение снаружи панели в `SettingsDrawer`, и разойдись они —
  /// дымка перестала бы обтекать углы.
  static const double drawerCornerRadius = 24;

  /// Отступ от края всплывающей поверхности до её содержимого. Диалоги,
  /// нижние листы и выбор времени держат один и тот же: окна открываются из
  /// одного места, и разные поля выдавали бы их как собранные по разным
  /// правилам.
  static const double popupPadding = 24;

  /// Поля диалога вокруг текста. Приходится задавать каждому `AlertDialog`
  /// вручную: `DialogThemeData` из всех отступов знает только `actionsPadding`,
  /// а собственное умолчание `AlertDialog` сверху уже 16, а не 24.
  static const EdgeInsets dialogContentPadding = EdgeInsets.all(popupPadding);

  /// Скругление всплывающих поверхностей — диалогов и нижних листов.
  static const BorderRadius dialogRadius = BorderRadius.all(
    Radius.circular(20),
  );
  static const BorderRadius sheetRadius = BorderRadius.vertical(
    top: Radius.circular(24),
  );

  /// Свечение, уходящее от края всплывающей поверхности наружу, на
  /// затемнённый экран: панели настроек, диалогов, нижних листов.
  static const Color edgeGlow = Color(0x33FFFFFF);

  static final ColorScheme _colorScheme =
      ColorScheme.fromSeed(
        seedColor: Colors.teal,
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFF5E9B90),
        surface: Colors.black,
        surfaceContainerLowest: Colors.black,
        surfaceContainerLow: surfaceCard,
        surfaceContainer: const Color(0xFF121212),
        surfaceContainerHigh: const Color(0xFF171717),
        surfaceContainerHighest: const Color(0xFF1F1F1F),
        onSurface: const Color(0xFFF2F2F2),
        onSurfaceVariant: const Color(0xFFA0A0A0),
        outline: const Color(0xFF3D3D3D),
        outlineVariant: const Color(0xFF1F1F1F),
      );

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    colorScheme: _colorScheme,
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      surfaceTintColor: Colors.black,
    ),
    iconTheme: const IconThemeData(size: 32, color: Colors.white),

    // Панель настроек чёрная, как и экран под ней, поэтому отделяет её не
    // подложка и не обводка, а скруглённый край со свечением снаружи — его
    // рисует сам `SettingsDrawer`, потому что `shape` клипится Material'ом.
    // Затемнение усилено, чтобы белые цифры счётчика не просвечивали сквозь.
    drawerTheme: const DrawerThemeData(
      backgroundColor: Colors.black,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrimColor: Color(0xCC000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(drawerCornerRadius),
        ),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: hairline,
      space: 1,
      thickness: 1,
    ),

    // Диалог и нижний лист всплывают поверх затемнённого экрана, и обводка
    // делала их плоскими вырезами в нём. Край держит то же свечение, что и
    // панель настроек, — приподнятость вместо контура.
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceCard,
      surfaceTintColor: Colors.transparent,
      contentTextStyle: TextStyle(color: _colorScheme.onSurface, fontSize: 16),
      shape: const EdgeGlowBorder(borderRadius: dialogRadius),

      // TextButton держит вокруг подписи собственные поля — 12 dp по бокам и
      // 10 dp сверху и снизу (подпись высотой 20 растянута до минимальной
      // высоты кнопки в 40). Ряд кнопок отодвинут от края ровно на столько
      // меньше: иначе подписи стоят дальше от края, чем текст над ними, и
      // правый край диалога выглядит просторнее левого.
      actionsPadding: const EdgeInsets.fromLTRB(
        popupPadding - 12,
        0,
        popupPadding - 12,
        popupPadding - 10,
      ),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.black,
      surfaceTintColor: Colors.transparent,
      shape: EdgeGlowBorder(borderRadius: sheetRadius),
    ),

    // Выбор времени напоминания живёт в собственной теме и `dialogTheme` не
    // наследует: без этого он единственный всплывал бы без светящегося края.
    timePickerTheme: const TimePickerThemeData(
      shape: EdgeGlowBorder(borderRadius: dialogRadius),
    ),

    // Делений десять, и точки под ползунком превращались в рябь: шаг и так
    // виден по подписи «Уровень N».
    sliderTheme: SliderThemeData(
      activeTickMarkColor: Colors.transparent,
      inactiveTickMarkColor: Colors.transparent,
      inactiveTrackColor: const Color(0xFF2A2A2A),
      overlayColor: _colorScheme.primary.withValues(alpha: 0.12),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (Set<WidgetState> states) => states.contains(WidgetState.selected)
            ? _colorScheme.primary
            : const Color(0xFF6E6E6E),
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (Set<WidgetState> states) => states.contains(WidgetState.selected)
            ? _colorScheme.primary.withValues(alpha: 0.32)
            : const Color(0xFF1A1A1A),
      ),
      trackOutlineColor: const WidgetStatePropertyAll<Color>(Color(0xFF3D3D3D)),
    ),
  );
}
