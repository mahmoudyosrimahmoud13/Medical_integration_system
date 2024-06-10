import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'get_doctor_state.dart';

class GetDoctorCubit extends Cubit<GetDoctorState> {
  GetDoctorCubit() : super(GetDoctorInitial());
}
