import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:healthhub/helpers/dio_helper.dart';
import 'package:meta/meta.dart';
import 'package:healthhub/helpers/helper_methods.dart';

part 'governrates_state.dart';

class GovernratesCubit extends Cubit<GovernratesState> {
  GovernratesCubit() : super(GovernratesInitial());

  void getGovernrates() async {
    try {
      final ResponseData responseData =
          await DioHelper.getData(endPoint: '/Adress/GetGovernorate');
      // print(responseData.response!.data);

      emit(GovernratesSuccess(data: responseData.response!.data));
    } catch (e) {
      // print(e.toString());
      showMessage(message: e.toString(), type: MessageType.faild);
      emit(GovernratesError(error: e.toString()));
    }
  }
}
