import 'package:final_project/logics/dio_helper.dart';
import 'package:final_project/logics/helper_methods.dart';
import 'package:final_project/pages/homepages/models/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../pages/homepages/entry_page.dart';

part 'login_cubit_state.dart';

class LoginCubit extends Cubit<LoginCubitState> {
  LoginCubit() : super(LoginCubitInitial());
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final formkey = GlobalKey<FormState>();
  AutovalidateMode autovalidateMode = AutovalidateMode.disabled;

  Future<void> login() async {
    if (formkey.currentState!.validate()) {
      emit(LoginCubitLoading());
      print("Loading");
      final response = await DioHelper.sendData(endPoint: "/Auth/Login", data: {
        'userName': emailController.text,
        'password': passwordController.text,
      });
      print('loading success');

      if (response.isSuccess == true) {
        print('isSuccuss');
        navigateTo(toPage: const EntryPage(), dontRemove: true);
        final model = UserrData.fromJson(response.response!.data);
        
        showMessage(message: 'Login Successfull', type: MessageType.success);
        emit(LoginCubitSuccess());
      } else {
        emit(LoginCubitFailed());
        showMessage(message: response.message);
        print('isFailed');
      }
    } else {
      autovalidateMode = AutovalidateMode.onUserInteraction;
    }
  }
}
