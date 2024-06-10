part of 'get_doctor_cubit.dart';

@immutable
sealed class GetDoctorState {}

final class GetDoctorInitial extends GetDoctorState {}

final class GetDoctorSuccess extends GetDoctorState {
  final Map<String, dynamic> data;

  GetDoctorSuccess({required this.data});
}

final class GetDoctorLoading extends GetDoctorState {}

final class GetDoctorError extends GetDoctorState {
  final String message;

  GetDoctorError({required this.message}) {
    showMessage(message: message, type: MessageType.faild);
  }
}
