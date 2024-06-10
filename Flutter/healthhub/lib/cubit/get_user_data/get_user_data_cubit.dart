import 'package:bloc/bloc.dart';
import 'package:healthhub/helpers/cache_helper.dart';
import 'package:healthhub/helpers/dio_helper.dart';
import 'package:meta/meta.dart';

part 'get_user_data_state.dart';

class GetUserDataCubit extends Cubit<GetUserDataState> {
  GetUserDataCubit() : super(GetUserDataInitial()) {}
  void getData() async {
    emit(GetUserDataLoading());
    try {
      ResponseData responseData = await DioHelper.getData(
          endPoint: '/Auth/GetUser',
          data: {'data': CacheHelper.getData(key: 'email')});
      final data = responseData.response!.data;
      emit(GetUserDataSuccess(data: data));
    } catch (e) {
      print(e.toString());
      GetUserDataError(message: e.toString());
    }
  }
}
