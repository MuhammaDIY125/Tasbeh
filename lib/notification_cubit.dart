import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

/// Хранит и персистирует время ежедневного напоминания.
///
/// Состояние `null` означает, что уведомления отключены.
class NotificationCubit extends HydratedCubit<TimeOfDay?> {
  NotificationCubit() : super(null);

  void setTime(TimeOfDay time) => emit(time);

  void disable() => emit(null);

  @override
  TimeOfDay? fromJson(Map<String, dynamic> json) {
    if (json['hour'] == null || json['minute'] == null) return null;
    return TimeOfDay(hour: json['hour'] as int, minute: json['minute'] as int);
  }

  @override
  Map<String, dynamic>? toJson(TimeOfDay? state) {
    if (state == null) return {'hour': null, 'minute': null};
    return {'hour': state.hour, 'minute': state.minute};
  }
}
