import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;

import 'app_theme.dart';
import 'custom_text_cubit.dart';
import 'l10n/app_localizations.dart';

/// Открывает свой текст пользователя в нижнем листе.
///
/// Лист, а не отдельный экран: текст читают между касаниями счётчика, и
/// счётчик должен оставаться под ним на месте. С главного экрана лист
/// открывается на чтение, из настроек — сразу на правку ([edit]). Пустой текст
/// открывается на правку всегда: читать там нечего.
Future<void> showCustomTextSheet(BuildContext context, {bool edit = false}) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CustomTextSheet(
        startEditing:
            edit || context.read<CustomTextCubit>().state.trim().isEmpty,
      ),
    );

/// Арабский шрифт приложения. Остальным строкам он подключён запасным: так
/// одиночное арабское слово внутри русской строки тоже рисуется им, а не
/// системным шрифтом с наползающими огласовками.
const String arabicFontFamily = 'Amiri';

class _CustomTextSheet extends StatefulWidget {
  final bool startEditing;

  const _CustomTextSheet({required this.startEditing});

  @override
  State<_CustomTextSheet> createState() => _CustomTextSheetState();
}

class _CustomTextSheetState extends State<_CustomTextSheet> {
  late bool _isEditing = widget.startEditing;

  void _startEditing() {
    Feedback.forLongPress(context);
    setState(() => _isEditing = true);
  }

  /// Стёртый целиком текст читать нечего, и лист вместо пустого режима
  /// чтения закрывается.
  void _finishEditing() {
    if (context.read<CustomTextCubit>().state.trim().isEmpty) {
      Navigator.pop(context);
      return;
    }
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);

    return Padding(
      // Клавиатура поднимает лист, а не перекрывает поле ввода.
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: ConstrainedBox(
        // Длинный текст прокручивается внутри листа, а не закрывает экран
        // целиком: полоса счётчика сверху напоминает, куда вернуться.
        constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // В режиме чтения кнопок нет: правка открывается долгим нажатием
            // на текст или из настроек, и лист остаётся одним текстом.
            if (_isEditing)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12),
                  child: IconButton(
                    tooltip: t.done,
                    onPressed: _finishEditing,
                    icon: Icon(
                      Icons.check_rounded,
                      size: 24,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            Flexible(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isEditing
                    ? const _CustomTextEditor(key: ValueKey(true))
                    : _CustomTextView(
                        key: const ValueKey(false),
                        onLongPress: _startEditing,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Текст в режиме чтения: каждая строка со своим направлением и шрифтом.
///
/// Обычно это арабский оригинал, транскрипция и перевод вперемешку. Арабские
/// строки крупнее и с большим интервалом: огласовки стоят над и под буквами, и
/// при обычном интервале строки наезжали бы друг на друга.
class _CustomTextView extends StatelessWidget {
  final VoidCallback onLongPress;

  const _CustomTextView({super.key, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final text = context.watch<CustomTextCubit>().state.trim();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: onLongPress,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.popupPadding,
          0,
          AppTheme.popupPadding,
          AppTheme.popupPadding,
        ),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              for (final line in text.split('\n')) _CustomTextLine(line.trim()),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomTextLine extends StatelessWidget {
  final String line;

  const _CustomTextLine(this.line);

  @override
  Widget build(BuildContext context) {
    // Пустая строка в тексте — отбивка между частями, а не строка высотой
    // в шрифт.
    if (line.isEmpty) return const SizedBox(height: 16);

    final color = Theme.of(context).colorScheme.onSurface;
    final isArabic = intl.Bidi.detectRtlDirectionality(line);

    return Text(
      line,
      textAlign: TextAlign.center,
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      style: isArabic
          ? TextStyle(
              fontFamily: arabicFontFamily,
              fontSize: 30,
              height: 1.9,
              color: color,
            )
          : TextStyle(
              fontSize: 18,
              height: 1.5,
              color: color,
              fontFamilyFallback: const [arabicFontFamily],
            ),
    );
  }
}

/// Поле правки. Каждая правка сохраняется сразу: лист можно смахнуть в любой
/// момент, и кнопка «Готово» не должна быть единственным способом не потерять
/// набранное.
class _CustomTextEditor extends StatefulWidget {
  const _CustomTextEditor({super.key});

  @override
  State<_CustomTextEditor> createState() => _CustomTextEditorState();
}

class _CustomTextEditorState extends State<_CustomTextEditor> {
  late final TextEditingController _controller = TextEditingController(
    text: context.read<CustomTextCubit>().state,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.popupPadding,
        0,
        AppTheme.popupPadding,
        AppTheme.popupPadding,
      ),
      child: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 6,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        textAlign: TextAlign.center,
        onChanged: context.read<CustomTextCubit>().setText,
        style: TextStyle(
          fontSize: 18,
          height: 1.6,
          color: colorScheme.onSurface,
          fontFamilyFallback: const [arabicFontFamily],
        ),
        decoration: InputDecoration(
          hintText: t.customTextHint,
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          filled: true,
          fillColor: colorScheme.surfaceContainerHigh,
          contentPadding: const EdgeInsets.all(16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
