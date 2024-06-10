import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:healthhub/helpers/dio_helper.dart';
import 'package:healthhub/helpers/helper_methods.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

part 'booking_state.dart';

class BookingCubit extends Cubit<BookingState> {
  BookingCubit() : super(BookingInitial());

  void book(
      {required id, required DateTime day, required TimeOfDay time}) async {
    final hour = DateTime.now().copyWith(hour: time.hour, minute: time.minute);
    emit(BookingLoading());
    try {
      final ResponseData responseData = await DioHelper.sendData(
          endPoint:
              '/Hospital/Patient/PushDateDoctor?DoctorId=9e721d6d-6e23-4329-86cf-cac01acb9185',
          data: {
            'from': DateFormat('hh:mm a').format(hour),
            'day': day.toIso8601String()
          });
      final data = responseData.response!.data;
      emit(BookingSucces(response: data.toString()));
      print(responseData.response!.data);
    } catch (e) {
      print(e.toString());
    }
  }
}
