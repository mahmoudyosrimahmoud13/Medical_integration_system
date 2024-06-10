import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:healthhub/helpers/dio_helper.dart';
import 'package:healthhub/helpers/helper_methods.dart';
import 'package:healthhub/screens/home/home_screen.dart';
import 'package:healthhub/widgets/appointment_card.dart';
import 'package:meta/meta.dart';

part 'get_appointments_state.dart';

class GetAppointmentsCubit extends Cubit<GetAppointmentsState> {
  GetAppointmentsCubit() : super(GetAppointmentsInitial());
  void get() async {
    emit(GetAppointmentsLoading());
    try {
      final ResponseData responseData = await DioHelper.getData(
          endPoint: '/Hospital/Patient/GetPatientDates');
      final data = responseData.response!.data;
      print(data);
      emit(GetAppointmentsSuccess(data: data));
    } catch (e) {
      print(e.toString());
      emit(GetAppointmentsError(message: e.toString()));
    }
  }

  void cancel({required String id}) async {
    emit(GetAppointmentsLoading());
    print(id);
    try {
      final ResponseData responseData = await DioHelper.deleteData(
        endPoint: '/Hospital/Patient/CancelBookedDate?PaintDateid=$id',
      );
      final data = responseData.response!.data;
      print(data);
      navigateTo(toPage: HomePage(), replace: true);
      emit(GetAppointmentsDelete(success: data));
    } catch (e) {
      print(e.toString());
      emit(GetAppointmentsError(message: e.toString()));
    }
  }
}
