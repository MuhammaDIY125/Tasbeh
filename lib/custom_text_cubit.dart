import 'package:hydrated_bloc/hydrated_bloc.dart';

/// Свой текст пользователя — зикр, дуа или что угодно, что читают при счёте.
class CustomTextCubit extends HydratedCubit<String> {
  CustomTextCubit() : super('');

  void setText(String text) => emit(text);

  @override
  String? fromJson(Map<String, dynamic> json) => json['text'] as String?;

  @override
  Map<String, dynamic>? toJson(String state) => {'text': state};
}
