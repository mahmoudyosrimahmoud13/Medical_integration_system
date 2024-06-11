import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:healthhub/helpers/dio_helper.dart';
import 'package:healthhub/widgets/prescription_card.dart';
import 'package:meta/meta.dart';

part 'get_prescriptions_state.dart';

class GetPrescriptionsCubit extends Cubit<GetPrescriptionsState> {
  GetPrescriptionsCubit() : super(GetPrescriptionsInitial());

  void get() async {
    emit(GetPrescriptionsLoading());
    try {
      ResponseData responseData = await DioHelper.getData(
          endPoint: '/Hospital/Patient/Information/Repentances');
      final data = responseData.response!.data;
      print(data);
      emit(GetPrescriptionsSuccess(data: data));
    } catch (e) {
      print(e.toString());
      emit(GetPrescriptionError(message: e.toString()));
    }
  }
}
