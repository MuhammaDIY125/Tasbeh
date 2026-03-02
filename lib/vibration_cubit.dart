import 'package:hydrated_bloc/hydrated_bloc.dart';

/// Хранит и персистирует состояние вибрации между сессиями.
class VibrationCubit extends HydratedCubit<bool> {
  VibrationCubit() : super(true);

  void toggle() => emit(!state);

  @override
  bool? fromJson(Map<String, dynamic> json) => json['vibration'] as bool?;

  @override
  Map<String, dynamic>? toJson(bool state) => {'vibration': state};
}
