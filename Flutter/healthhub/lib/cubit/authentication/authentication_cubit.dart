import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:healthhub/cubit/get_user_data/get_user_data_cubit.dart';
import 'package:healthhub/helpers/cache_helper.dart';
import 'package:healthhub/helpers/dio_helper.dart';
import 'package:healthhub/helpers/helper_methods.dart';
import 'package:healthhub/screens/authentication/login.dart';
import 'package:healthhub/screens/home/home_screen.dart';
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
      final message = responseData.response!.data['message'];

      if (responseData.response!.data['token'] != null) {
        CacheHelper.saveData(
            key: 'token', value: responseData.response!.data['token']);
        CacheHelper.saveData(
            key: 'area', value: responseData.response!.data['area']);
        CacheHelper.saveData(
            key: 'governrate', value: responseData.response!.data['gove']);
        CacheHelper.saveData(key: 'email', value: data['email']);
        CacheHelper.saveData(
            key: 'image', value: responseData.response!.data['imgSrc']);
        BlocProvider.of<GetUserDataCubit>(navigatorKey.currentState!.context)
            .getData();

        print(CacheHelper.getData(key: 'image'));
      }
      if (message == null) {
        showMessage(message: 'Login successful');
        navigateTo(toPage: const HomePage(), replace: true);
      } else {
        showMessage(message: message!, type: MessageType.faild);
      }

      emit(AuthenticationSuccess(message: message));
    } catch (e) {
      emit(AuthenticationError(error: e.toString()));
    }
  }

  void forgotPassword({required String email}) async {
    emit(AuthenticationLoading());
    try {
      ResponseData responseData = await DioHelper.sendData(
          endPoint: '/Auth/ForgetPassword', data: {'email': email});
      showMessage(message: 'Please check your email: $email');
      emit(AuthenticationSuccess(message: 'Email'));
      navigateTo(toPage: LoginScreen(), replace: true);
    } catch (e) {
      showMessage(message: e.toString());
      emit(AuthenticationError(error: e.toString()));
    }
  }
}
