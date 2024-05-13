import 'package:final_project/logics/dio_helper.dart';
import 'package:final_project/logics/helper_methods.dart';
import 'package:final_project/pages/SignUp/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'register_cubit_state.dart';

class RegisterCubit extends Cubit<RegisterStates> {
  RegisterCubit() : super(RegisterCubitInitial());
  static RegisterCubit get(context) => BlocProvider.of(context);

  void updateBirthdayField(String newText) {
    dateController.text = newText;
  }

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final formkey = GlobalKey<FormState>();
  bool isMale = true;
  String selectedArea = 'Area';
  AutovalidateMode autovalidateMode = AutovalidateMode.disabled;

  Future<void> postform() async {
    if (formkey.currentState!.validate()) {
      print(fullNameController.text);
      print(emailController.text);
      print(passwordController.text);
      print(confirmPasswordController.text);
      print(phoneNumberController.text);
      print(dateController.text);
      print(selectedArea);
      print(isMale);
      emit(RegisterCubitLoading());
      print('loading');
      final response =
          await DioHelper.sendFormData(endPoint: '/Auth/Register', data: {
        'input': {
          'name': fullNameController.text,
          'email': emailController.text,
          'password': passwordController.text,
          'passwordConfirm': confirmPasswordController.text,
          'phone': phoneNumberController.text,
          'birthday': dateController.text,
          'area': selectedArea,
          'gender': isMale ? 'male' : 'female'
        }
      });
      print('loading success');

      if (response.isSuccess) {
        showMessage(message: response.message);
        print('isSuccess');
        navigateTo(toPage: const LoginPage());
        emit(RegisterCubitSuccess());
      } else {
        print('failed');
        showMessage(message: response.message);
        emit(RegisterCubitFailed());
        print(response.response.toString());
      }
    } else {
      autovalidateMode = AutovalidateMode.onUserInteraction;
    }

    // try {
    //   FormData formData = FormData();
    //   Map<String, dynamic> input = {
    //     'name': fullNameController.text,
    //     'email': emailController.text,
    //     'password': passwordController.text,
    //     'passwordConfirm': confirmPasswordController.text,
    //     'phone': phoneNumberController.text,
    //     'birthday': dateController.text,
    //     'area': selectedArea,
    //     'gender': isMale
    //         ? 'male'
    //         : 'female', // Assuming the API expects 'male' or 'female'
    //   };
    //   formData.fields.addAll([MapEntry('input', input.toString())]);

    //   Response response = await Dio().post(
    //     '/Auth/Register',
    //     data: formData,
    //   );
  }
}
