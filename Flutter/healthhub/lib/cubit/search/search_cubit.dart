import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:healthhub/helpers/cache_helper.dart';
import 'package:healthhub/helpers/dio_helper.dart';
import 'package:healthhub/helpers/helper_methods.dart';
import 'package:healthhub/widgets/doctor_card.dart';
import 'package:meta/meta.dart';

part 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  SearchCubit() : super(SearchInitial());

  void getDoctorsInGovernorate({
    String? governrate,
    String? area,
    required String specialtie,
  }) async {
    emit(SearchLoading());
    print('dsdsadasdasdsadsadsa');
    try {
      print('-------------------------------------------5');
      ResponseData responseData = await DioHelper.getData(
          endPoint: '/Hospital/Doctor/GetDoctorsInGovernorate',
          data: {
            'area': area,
            'goveId': governrate,
            'specialtie': specialtie,
            'rate': true,
            'joinDate': true,
            'index': '0'
          });
      print('*******************************Data:');
      final data = responseData.response!.data;
      print(responseData.response!.data);
      emit(SearchSuccess(data: data));
    } catch (e) {
      print(e.toString());
      emit(SearchError(message: e.toString()));
    }
  }

  void serchDoctorsWithName({
    String? governrate,
    String? area,
    required String name,
    required String specialtie,
  }) async {
    emit(SearchLoading());
    print('dsdsadasdasdsadsadsa');
    try {
      print('-------------------------------------------5');
      ResponseData responseData = await DioHelper.getData(
          endPoint: '/Hospital/Doctor/SerchDoctorsWithName',
          data: {
            'DoctorName': name,
            'area': area,
            'goveId': governrate,
            'specialtie': specialtie,
            'rate': true,
            'joinDate': true,
            'index': '0'
          });
      final data = responseData.response!.data;

      print(responseData.response!.data);
      emit(SearchSuccess(data: data));

      print(CacheHelper.getData(key: 'token'));
      print('*******************************');
    } catch (e) {
      print(e.toString());
      emit(SearchError(message: e.toString()));
    }
  }
}
