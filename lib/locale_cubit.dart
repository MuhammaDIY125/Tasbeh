import 'package:hydrated_bloc/hydrated_bloc.dart';

class LocaleCubit extends HydratedCubit<String> {
  LocaleCubit() : super('uz');

  void setLocale(String code) => emit(code);

  @override
  String? fromJson(Map<String, dynamic> json) {
    return json['locale'] as String?;
  }

  @override
  Map<String, dynamic>? toJson(String state) {
    return {'locale': state};
  }
}
