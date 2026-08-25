import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

/// Состояние напоминания, включающее статус и время.
///
/// `time` хранится и при выключенном напоминании: так повторное включение
/// открывает выбор времени с последним выбранным значением, а не со сбитым
/// дефолтом.
class NotificationState {
  final bool isEnabled;
  final TimeOfDay time;

  const NotificationState({required this.isEnabled, required this.time});

  NotificationState copyWith({bool? isEnabled, TimeOfDay? time}) {
    return NotificationState(
      isEnabled: isEnabled ?? this.isEnabled,
      time: time ?? this.time,
    );
  }

  Map<String, dynamic> toJson() => {
    'isEnabled': isEnabled,
    'hour': time.hour,
    'minute': time.minute,
  };

  factory NotificationState.fromJson(Map<String, dynamic> json) {
    return NotificationState(
      isEnabled: json['isEnabled'] as bool? ?? false,
      time: TimeOfDay(
        hour: json['hour'] as int? ?? 6,
        minute: json['minute'] as int? ?? 0,
      ),
    );
  }
}

/// Хранит и персистирует время ежедневного напоминания.
class NotificationCubit extends HydratedCubit<NotificationState> {
  NotificationCubit()
    : super(
        const NotificationState(
          isEnabled: false,
          time: TimeOfDay(hour: 6, minute: 0),
        ),
      );

  void setTime(TimeOfDay time) =>
      emit(state.copyWith(isEnabled: true, time: time));

  void disable() => emit(state.copyWith(isEnabled: false));

  @override
  NotificationState? fromJson(Map<String, dynamic> json) {
    // Поддержка старого формата, где состояние было просто `TimeOfDay?`.
    if (json.containsKey('isEnabled')) return NotificationState.fromJson(json);

    if (json['hour'] == null || json['minute'] == null) {
      return const NotificationState(
        isEnabled: false,
        time: TimeOfDay(hour: 6, minute: 0),
      );
    }
    return NotificationState(
      isEnabled: true,
      time: TimeOfDay(hour: json['hour'] as int, minute: json['minute'] as int),
    );
  }

  @override
  Map<String, dynamic>? toJson(NotificationState state) => state.toJson();
}
