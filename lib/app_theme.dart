import 'package:flutter/material.dart';

import 'edge_glow.dart';
import 'theme_cubit.dart';

/// Тема приложения в цветах выбранной [ThemePalette] — тёмная или светлая
/// по яркости её фона.
///
/// Все поверхности — панель настроек, листы, диалоги — строятся от фона
/// темы, а не от seed'а: сгенерированные из акцента оттенки тянутся за ним
/// (у бирюзы `surfaceContainerLow` — `#161D1C`) и поверх фона читались бы
/// как посторонняя плита другого цвета. Поверхность на ступень выше — это фон
/// темы под полупрозрачной вуалью цвета текста: на тёмной теме чуть светлее
/// фона, на светлой чуть темнее, и в обоих случаях в оттенке самой темы.
///
/// Акцент тоже не берётся из seed'а: сгенерированный `primary` (у бирюзы —
/// `#82D5C8`) слишком звонкий для приложения, которое должно оставаться фоном
/// для зикра, а не притягивать взгляд. Поэтому `primary` —
/// [ThemePalette.accent] как есть.
class AppTheme {
  const AppTheme._();

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

  /// То же свечение для светлых тем. Белое на светлом экране не видно, и
  /// край держит мягкая тень той же формы.
  static const Color edgeShadow = Color(0x33000000);

  static Color edgeGlowFor(Brightness brightness) =>
      brightness == Brightness.dark ? edgeGlow : edgeShadow;

  static ThemeData of(ThemePalette palette) =>
      _build(palette, _colorScheme(palette));

  static bool _isDark(ThemePalette palette) =>
      palette.brightness == Brightness.dark;

  /// Фон темы под вуалью цвета текста заданной плотности. Плотности подобраны
  /// так, что на чёрном выходят прежние нейтральные ступени: `0.05` —
  /// `#0D0D0D`, `0.12` — `#1F1F1F`, `0.24` — `#3D3D3D`.
  static Color _veil(ThemePalette palette, double alpha) => Color.alphaBlend(
    (_isDark(palette) ? Colors.white : Colors.black).withValues(alpha: alpha),
    palette.background,
  );

  static ColorScheme _colorScheme(ThemePalette palette) {
    final isDark = _isDark(palette);

    return ColorScheme.fromSeed(
      seedColor: palette.accent,
      brightness: palette.brightness,
    ).copyWith(
      primary: palette.accent,
      // Сгенерированный `onPrimary` даёт с приглушённым акцентом контраст
      // около 4:1 — ниже порога для текста на кнопке. Чёрный на светлых
      // акцентах тёмных тем и белый на тёмных акцентах светлых дают больше
      // 5:1 у любой темы.
      onPrimary: isDark ? Colors.black : Colors.white,
      // Кнопка «Сброс»: на тёмных темах прежний `redAccent`, на светлых он
      // даёт меньше 3:1, и нужен красный темнее.
      error: isDark ? Colors.redAccent : const Color(0xFFB3261E),
      surface: palette.background,
      surfaceContainerLowest: palette.background,
      // Фон карточек и диалогов: ровно настолько отличается от экрана, чтобы
      // читаться отдельным листом и не спорить со счётчиком.
      surfaceContainerLow: _veil(palette, 0.05),
      surfaceContainer: _veil(palette, 0.07),
      surfaceContainerHigh: _veil(palette, 0.09),
      surfaceContainerHighest: _veil(palette, 0.12),
      onSurface: isDark ? const Color(0xFFF2F2F2) : const Color(0xFF1C1C1C),
      onSurfaceVariant: isDark
          ? const Color(0xFFA0A0A0)
          : const Color(0xFF55554F),
      outline: _veil(palette, 0.24),
      outlineVariant: _veil(palette, 0.12),
    );
  }

  static ThemeData _build(ThemePalette palette, ColorScheme colorScheme) {
    final isDark = _isDark(palette);
    final edge = edgeGlowFor(palette.brightness);

    return ThemeData(
      brightness: palette.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surface,
      ),

      // Иконки и цифры экрана счётчика — самого контрастного к фону цвета:
      // на тёмных темах чисто белые, как были всегда.
      iconTheme: IconThemeData(
        size: 32,
        color: isDark ? Colors.white : colorScheme.onSurface,
      ),

      // Панель настроек того же цвета, что и экран под ней, поэтому отделяет
      // её не подложка и не обводка, а скруглённый край со свечением снаружи —
      // его рисует сам `SettingsDrawer`, потому что `shape` клипится
      // Material'ом. На тёмных темах затемнение усилено, чтобы белые цифры
      // счётчика не просвечивали сквозь; на светлых тёмные цифры под ним и
      // так гаснут, а плотная чернота превращала бы светлую тему в тёмную.
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrimColor: isDark ? const Color(0xCC000000) : const Color(0x66000000),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(drawerCornerRadius),
          ),
        ),
      ),

      // Разделители внутри поверхностей. Края самих поверхностей ими не
      // обводятся: обводка делала всплывающее окно плоским вырезом в экране,
      // а не листом поверх него.
      dividerTheme: DividerThemeData(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
        space: 1,
        thickness: 1,
      ),

      // Диалог и нижний лист всплывают поверх затемнённого экрана, и обводка
      // делала их плоскими вырезами в нём. Край держит то же свечение, что и
      // панель настроек, — приподнятость вместо контура.
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        contentTextStyle: TextStyle(color: colorScheme.onSurface, fontSize: 16),
        shape: EdgeGlowBorder(borderRadius: dialogRadius, color: edge),

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

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: EdgeGlowBorder(borderRadius: sheetRadius, color: edge),
      ),

      // Выбор времени напоминания живёт в собственной теме и `dialogTheme` не
      // наследует: без этого он единственный всплывал бы без светящегося края.
      timePickerTheme: TimePickerThemeData(
        shape: EdgeGlowBorder(borderRadius: dialogRadius, color: edge),
      ),

      // Делений десять, и точки под ползунком превращались в рябь: шаг и так
      // виден по подписи «Уровень N».
      sliderTheme: SliderThemeData(
        activeTickMarkColor: Colors.transparent,
        inactiveTickMarkColor: Colors.transparent,
        inactiveTrackColor: _veil(palette, 0.165),
        overlayColor: colorScheme.primary.withValues(alpha: 0.12),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? colorScheme.primary
              : _veil(palette, 0.43),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? colorScheme.primary.withValues(alpha: 0.32)
              : _veil(palette, 0.10),
        ),
        trackOutlineColor: WidgetStatePropertyAll<Color>(colorScheme.outline),
      ),
    );
  }
}
