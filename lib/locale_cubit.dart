import 'dart:ui';

import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'l10n/app_localizations.dart';

/// Язык интерфейса в виде кода локали (`uz`, `ru`, `en`).
///
/// При первом запуске подхватывается язык системы, дальше `HydratedCubit`
/// восстанавливает выбор, сделанный пользователем в настройках.
class LocaleCubit extends HydratedCubit<String> {
  LocaleCubit() : super(_systemLanguageCode());

  /// Язык, на который приложение откатывается, если система просит перевод,
  /// которого у нас нет.
  static const fallbackLanguageCode = 'en';

  /// Языки, для которых сгенерированы переводы из `lib/l10n/*.arb`.
  static final Set<String> supportedLanguageCodes = AppLocalizations
      .supportedLocales
      .map((locale) => locale.languageCode)
      .toSet();

  void setLocale(String code) => emit(code);

  /// Первый из предпочитаемых системой языков, для которого есть перевод.
  ///
  /// `PlatformDispatcher.instance.locales` — это упорядоченный список языков
  /// из настроек устройства, поэтому пользователь со связкой «ru, en»
  /// получит русский, а не английский.
  static String _systemLanguageCode() {
    for (final locale in PlatformDispatcher.instance.locales) {
      if (supportedLanguageCodes.contains(locale.languageCode)) {
        return locale.languageCode;
      }
    }
    return fallbackLanguageCode;
  }

  /// Возвращает null для неизвестного кода: тогда `HydratedCubit` оставит
  /// начальное состояние — язык системы.
  @override
  String? fromJson(Map<String, dynamic> json) {
    final code = json['locale'] as String?;
    return supportedLanguageCodes.contains(code) ? code : null;
  }

  @override
  Map<String, dynamic>? toJson(String state) {
    return {'locale': state};
  }
}
