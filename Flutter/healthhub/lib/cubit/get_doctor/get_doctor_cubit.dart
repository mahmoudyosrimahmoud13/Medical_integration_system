import 'package:bloc/bloc.dart';
import 'package:healthhub/helpers/dio_helper.dart';
import 'package:healthhub/helpers/helper_methods.dart';
import 'package:meta/meta.dart';

part 'get_doctor_state.dart';

class GetDoctorCubit extends Cubit<GetDoctorState> {
  GetDoctorCubit() : super(GetDoctorInitial());
  void getDoctor({required String id}) async {
    emit(GetDoctorLoading());
    try {
      ResponseData responseData = await DioHelper.getData(
          endPoint: '/Hospital/Doctor/GetDoctor', data: {'Id': id});
      final data = responseData.response!.data;
      print(data);
      emit(GetDoctorSuccess(data: data));
    } catch (e) {
      print(e.toString());
      emit(GetDoctorError(message: e.toString()));
    }
  }
}
