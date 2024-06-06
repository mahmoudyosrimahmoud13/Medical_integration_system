import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:healthhub/helpers/dio_helper.dart';
import 'package:meta/meta.dart';

part 'adress_state.dart';

class AdressCubit extends Cubit<AdressState> {
  AdressCubit() : super(AdressInitial()) {
    getGovernrates();
  }

  dynamic governrates = [];
  // final Map<String, dynamic> govenrates;
  void getGovernrates() async {
    print('object=============================');

    emit(AdressLoading());
    try {
      final response =
          await DioHelper.getData(endPoint: '/Adress/GetGovernorate');
      final governrtes = response.response!.data;
      Map key = {'key': 'Choose governarate first'};
      emit(AdressSucsses(data: governrtes, key: [key]));
    } catch (e) {
      print(e.toString());
    }
  }

  void getAreas({required String key}) async {
    try {
      final governrateResponse =
          await DioHelper.getData(endPoint: '/Adress/GetGovernorate');
      final governrtes = governrateResponse.response!.data;
      final areaResponse = await DioHelper.getData(
          endPoint: '/Adress/GetAreas', data: {'GovermentKey': key});
      print(key);

      print('area========');
      final areas = areaResponse.response!.data;
      print('dksjk' + areas.toString());
      emit(AdressSucsses(data: governrtes, key: areas));
    } catch (e) {
      print(e.toString());
    }
  }
}
