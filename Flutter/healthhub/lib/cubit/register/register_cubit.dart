import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:healthhub/helpers/dio_helper.dart';
import 'package:healthhub/helpers/helper_methods.dart';
import 'package:healthhub/models/register_user_model.dart';
import 'package:healthhub/screens/authentication/login.dart';
import 'package:http_parser/http_parser.dart';

part 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit() : super(RegisterInitial()) {}

  void Register({required RegisterUserModel model}) async {
    emit(RegisterLoading());
    MultipartFile? img;
    if (model.image != null) {
      img = await MultipartFile.fromFile(model.image!.path,
          filename: model.image!.path, contentType: MediaType('image', 'png'));
    }
    try {
      print(model.toMap());
      final ResponseData response = await DioHelper.sendFormData(
          endPoint: '/Auth/Register',
          data: {
            'img': model.image == null ? null : img,
            'input': json.encode(model.toMap())
          });
      print(response.response!.data);
      emit(RegisterSuccess(message: response.response!.data['message']));
      navigateTo(toPage: LoginScreen(), replace: true);
    } catch (e) {
      showMessage(message: e.toString(), type: MessageType.faild);
      print(e.toString());
      emit(RegisterError(error: e.toString()));
    }
  }
}
