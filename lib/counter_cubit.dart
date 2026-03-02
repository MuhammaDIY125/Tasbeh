import 'package:flutter/services.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class CounterCubit extends HydratedCubit<int> {
  CounterCubit() : super(0);

  void increment({bool vibrate = true}) {
    if (vibrate) HapticFeedback.heavyImpact();
    emit(state + 1);
  }

  void decrement() {
    if (state > 0) {
      emit(state - 1);
    }
  }

  void reset() {
    if (state != 0) {
      emit(0);
    }
  }

  @override
  int? fromJson(Map<String, dynamic> json) {
    return json['value'] is int ? json['value'] as int : null;
  }

  @override
  Map<String, dynamic>? toJson(int state) {
    return {'value': state};
  }
}
