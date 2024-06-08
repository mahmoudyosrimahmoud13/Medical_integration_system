import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:healthhub/helpers/cache_helper.dart';
import 'package:healthhub/helpers/dio_helper.dart';
import 'package:meta/meta.dart';

part 'authentication_state.dart';

class AuthenticationCubit extends Cubit<AuthenticationState> {
  AuthenticationCubit() : super(AuthenticationInitial());

  void login({required Map<String, dynamic> data}) async {
    emit(AuthenticationLoading());
    try {
      CacheHelper.init();
      ResponseData responseData =
          await DioHelper.sendData(endPoint: '/Auth/Login', data: data);
      print(responseData.response!.data);

      if (responseData.response!.data['message'] != null) {
        CacheHelper.saveData(
            key: 'token', value: responseData.response!.data['token']);
      }
      print(CacheHelper.getData(key: 'token'));
      emit(AuthenticationSuccess(
          message: responseData.response!.data['message']));
    } catch (e) {
      emit(AuthenticationError(error: e.toString()));
    }
  }
}
