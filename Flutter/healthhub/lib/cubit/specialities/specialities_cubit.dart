import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:healthhub/helpers/dio_helper.dart';
import 'package:meta/meta.dart';
import 'package:healthhub/helpers/helper_methods.dart';

part 'specialities_state.dart';

class SpecialitiesCubit extends Cubit<SpecialitiesState> {
  SpecialitiesCubit() : super(SpecialitiesInitial());

  void getSpecialities() async {
    try {
      final ResponseData responseData =
          await DioHelper.getData(endPoint: '/Hospital/Specialties');
      // print(responseData.response!.data);

      emit(SpecialitiesSuccess(data: responseData.response!.data));
    } catch (e) {
      // print(e.toString());
      showMessage(message: e.toString(), type: MessageType.faild);
      emit(SpecialitiesError(error: e.toString()));
    }
  }
}
