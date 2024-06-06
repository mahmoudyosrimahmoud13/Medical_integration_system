import 'package:bloc/bloc.dart';
import 'package:healthhub/helpers/dio_helper.dart';
import 'package:meta/meta.dart';

part 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit() : super(RegisterInitial()) {}
}
