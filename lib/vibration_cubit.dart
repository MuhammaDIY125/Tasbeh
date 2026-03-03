import 'package:hydrated_bloc/hydrated_bloc.dart';

/// Состояние вибрации, включающее статус и интенсивность.
class VibrationState {
  final bool isEnabled;
  final int intensity;

  const VibrationState({required this.isEnabled, required this.intensity});

  VibrationState copyWith({bool? isEnabled, int? intensity}) {
    return VibrationState(
      isEnabled: isEnabled ?? this.isEnabled,
      intensity: intensity ?? this.intensity,
    );
  }

  Map<String, dynamic> toJson() => {
    'isEnabled': isEnabled,
    'intensity': intensity,
  };

  factory VibrationState.fromJson(Map<String, dynamic> json) {
    return VibrationState(
      isEnabled: json['isEnabled'] as bool? ?? true,
      intensity: json['intensity'] as int? ?? 128,
    );
  }
}

/// Хранит и персистирует состояние вибрации между сессиями.
class VibrationCubit extends HydratedCubit<VibrationState> {
  VibrationCubit()
    : super(const VibrationState(isEnabled: true, intensity: 128));

  void toggle() => emit(state.copyWith(isEnabled: !state.isEnabled));

  void setIntensity(int intensity) =>
      emit(state.copyWith(intensity: intensity));

  @override
  VibrationState? fromJson(Map<String, dynamic> json) {
    // Поддержка старого формата (просто bool)
    if (json['vibration'] is bool) {
      return VibrationState(
        isEnabled: json['vibration'] as bool,
        intensity: 128,
      );
    }
    return VibrationState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(VibrationState state) => state.toJson();
}
