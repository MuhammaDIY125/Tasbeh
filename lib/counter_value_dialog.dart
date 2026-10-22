import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_theme.dart';
import 'counter_cubit.dart';
import 'counter_page.dart';
import 'l10n/app_localizations.dart';

/// Спрашивает новое значение счётчика и ставит его.
///
/// Заголовка нет: крупное число в поле само говорит, что меняется.
Future<void> showCounterValueDialog(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => const _CounterValueDialog(),
);

class _CounterValueDialog extends StatefulWidget {
  const _CounterValueDialog();

  /// Шесть цифр — с запасом на любой зикр и без числа шире диалога.
  static const int _maxDigits = 6;

  @override
  State<_CounterValueDialog> createState() => _CounterValueDialogState();
}

class _CounterValueDialogState extends State<_CounterValueDialog> {
  // Текущее число выделено целиком: новое набирают поверх, не стирая старое.
  late final TextEditingController _controller = () {
    final current = '${context.read<CounterCubit>().state}';
    return TextEditingController(text: current)
      ..selection = TextSelection(baseOffset: 0, extentOffset: current.length);
  }();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = int.tryParse(_controller.text);
    if (value == null) return;
    context.read<CounterCubit>().setValue(value);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      contentPadding: AppTheme.dialogContentPadding,
      content: TextField(
        controller: _controller,
        autofocus: true,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(_CounterValueDialog._maxDigits),
        ],
        onSubmitted: (_) => _save(),
        style: CounterPage.numberStyle.copyWith(color: colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: '0',
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          border: InputBorder.none,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        // Пустое поле не считается нулём: стёртое число — это ещё не
        // набранное новое, и случайное «Сохранить» не должно обнулять счёт.
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, _) => TextButton(
            onPressed: value.text.isEmpty ? null : _save,
            child: Text(t.save),
          ),
        ),
      ],
    );
  }
}
