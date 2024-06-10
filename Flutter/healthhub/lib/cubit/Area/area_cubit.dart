import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:healthhub/helpers/cache_helper.dart';
import 'package:healthhub/helpers/dio_helper.dart';
import 'package:meta/meta.dart';
import 'package:healthhub/helpers/helper_methods.dart';

part 'area_state.dart';

class AreaCubit extends Cubit<AreaState> {
  AreaCubit() : super(AreaInitial()) {}

  void getArea() async {
    try {
      final ResponseData responseData = await DioHelper.getData(
          endPoint: '/Adress/GetAreas',
          data: {'GovermentKey': CacheHelper.getData(key: 'governrate')});

      // print(responseData.response!.data[0]);

      emit(AreaSuccess(data: responseData.response!.data));
    } catch (e) {
      // print(e.toString());
      showMessage(message: e.toString(), type: MessageType.faild);
      emit(AreaError(error: e.toString()));
    }
  }
}
